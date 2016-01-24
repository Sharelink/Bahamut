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
    private var tagData:String!
    @IBOutlet weak var focusSwitch: UISwitch!
    
    @IBOutlet weak var showToLinkerSwitch: UISwitch!
    @IBOutlet weak var tagColorView: UIView!{
        didSet{
            tagColorView.layer.cornerRadius = 3
            tagColorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectColor:"))
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
    
    func selectColor(_:UITapGestureRecognizer)
    {
        tagColorView.backgroundColor = UIColor.getRandomTextColor()
    }
    
    private func update()
    {
        tagNameLabel.text = themeModel.getEditingName()
        tagColorView.backgroundColor = UIColor(hexString: themeModel.tagColor)
        focusSwitch.on = themeModel.isFocus == "true"
        showToLinkerSwitch.on = themeModel.showToLinkers == "true"
    }
    
    @IBAction func save(sender: AnyObject)
    {
        if String.isNullOrWhiteSpace(tagNameLabel.text)
        {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("THEME_NAME_NULL_ERR", comment: ""), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        themeModel.tagName = tagNameLabel.text
        themeModel.tagColor = tagColorView.backgroundColor?.toHexString()
        themeModel.isFocus = focusSwitch.on ? "true":"false"
        themeModel.data = tagData ?? themeModel.tagName;
        themeModel.showToLinkers = showToLinkerSwitch.on ? "true":"false"
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
        return instanceFromStoryBoard("Component", identifier: "EditThemeViewController",bundle: Sharelink.mainBundle) as! EditThemeViewController
    }
    
}