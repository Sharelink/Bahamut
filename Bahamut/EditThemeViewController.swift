//
//  EditThemeViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit


//MARK: UserService extension
extension UserService
{
    func showUserThemeEditController(currentNavigationController:UINavigationController,editModel:SharelinkTheme,editMode:UserThemeEditMode,delegate:EditThemeViewControllerDelegate)
    {
        let controller = EditThemeViewController.instanceFromStoryBoard()
        controller.delegate = delegate
        controller.themeModel = editModel
        controller.editMode = editMode
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

@objc
protocol EditThemeViewControllerDelegate
{
    optional func editThemeViewControllerSave(saveModel:SharelinkTheme,sender:EditThemeViewController)
}

enum UserThemeEditMode
{
    case New
    case Edit
}

//MARK:EditThemeViewController
class EditThemeViewController: UIViewController
{
    @IBOutlet weak var tagNameLabel: UITextField!
    
    @IBOutlet weak var tagTypeLabel: UILabel!
    private var themeData:String!
    
    @IBOutlet weak var isFocusImgView: UIImageView!{
        didSet{
            isFocusImgView.userInteractionEnabled = true
            isFocusImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EditThemeViewController.onIsFocusClicked(_:))))
        }
    }
    @IBOutlet weak var isShowToFriendsImgView: UIImageView!{
        didSet{
            isShowToFriendsImgView.userInteractionEnabled = true
            isShowToFriendsImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EditThemeViewController.onIsShowToFriendsClicked(_:))))
        }
    }
    @IBOutlet weak var themeColorView: UIView!{
        didSet{
            themeColorView.layer.cornerRadius = 3
            themeColorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EditThemeViewController.selectColor(_:))))
        }
    }
    
    private var isFocusTheme:Bool = true{
        didSet{
            if isFocusImgView != nil{
                isFocusImgView.image = isFocusTheme ? UIImage.namedImageInSharelink("heart") : UIImage.namedImageInSharelink("gray_heart")
            }
        }
    }
    
    private var isShowToFriends:Bool = true{
        didSet{
            if isShowToFriendsImgView != nil{
                isShowToFriendsImgView.image = isShowToFriends ? UIImage.namedImageInSharelink("unlock") : UIImage.namedImageInSharelink("lock")
            }
        }
    }
    
    var delegate:EditThemeViewControllerDelegate!
    var themeModel:SharelinkTheme!
    var editMode:UserThemeEditMode = .New

    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.update()
    }
    
    @IBAction func changeTagType(sender: AnyObject)
    {
        
    }
    
    func onIsShowToFriendsClicked(a:UITapGestureRecognizer)
    {
        if let view = a.view
        {
            view.animationMaxToMin(0.1, maxScale: 1.3, completion: { () -> Void in
                self.isShowToFriends = !self.isShowToFriends
            })
        }
    }
    
    func onIsFocusClicked(a:UITapGestureRecognizer)
    {
        if let view = a.view
        {
            view.animationMaxToMin(0.1, maxScale: 1.3, completion: { () -> Void in
                self.isFocusTheme = !self.isFocusTheme
            })
        }
    }
    
    func selectColor(a:UITapGestureRecognizer)
    {
        if let view = a.view
        {
            view.animationMaxToMin(0.1, maxScale: 1.3, completion: { () -> Void in
                self.themeColorView.backgroundColor = UIColor.getRandomTextColor()
            })
        }
        
    }
    
    private func update()
    {
        tagNameLabel.text = themeModel.getEditingName()
        themeColorView.backgroundColor = UIColor(hexString: themeModel.tagColor)
        isFocusTheme = themeModel.isFocus == "true"
        isShowToFriends = themeModel.showToLinkers == "true"
    }
    
    @IBAction func save(sender: AnyObject)
    {
        if String.isNullOrWhiteSpace(tagNameLabel.text)
        {
            let alert = UIAlertController(title: nil, message: "THEME_NAME_NULL_ERR".localizedString(), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        themeModel.tagName = tagNameLabel.text
        themeModel.tagColor = themeColorView.backgroundColor?.toHexString()
        themeModel.isFocus = isFocusTheme ? "true":"false"
        themeModel.data = themeData ?? themeModel.tagName;
        themeModel.showToLinkers = isShowToFriends ? "true":"false"
        themeModel.type = SharelinkThemeConstant.TAG_TYPE_KEYWORD
        if let saveHandler = delegate?.editThemeViewControllerSave
        {
            saveHandler(themeModel,sender: self)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("EditThemeView")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("EditThemeView")
    }
    
    static func instanceFromStoryBoard() -> EditThemeViewController
    {
        return instanceFromStoryBoard("Component", identifier: "EditThemeViewController",bundle: Sharelink.mainBundle()) as! EditThemeViewController
    }
    
}