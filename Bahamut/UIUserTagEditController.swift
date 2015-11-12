//
//  UIUserTagEditController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import SharelinkSDK

//MARK: UserService extension
extension UserService
{
    func showUIUserTagEditController(currentNavigationController:UINavigationController,editModel:UISharelinkTagItemModel,editMode:UIUserTagEditMode,delegate:UIUserTagEditControllerDelegate)
    {
        let userTagEditController = UIUserTagEditController.instanceFromStoryBoard()
        userTagEditController.delegate = delegate
        userTagEditController.tagModel = editModel
        userTagEditController.editMode = editMode
        currentNavigationController.pushViewController(userTagEditController, animated: true)
    }
}

@objc
protocol UIUserTagEditControllerDelegate
{
    optional func tagEditControllerSave(saveModel:UISharelinkTagItemModel,sender:UIUserTagEditController)
}

enum UIUserTagEditMode
{
    case New
    case Edit
}

class UIUserTagEditController: UIViewController
{
    @IBOutlet weak var tagNameLabel: UITextField!{
        didSet{
            update()
        }
    }
    
    @IBOutlet weak var tagTypeLabel: UILabel!{
        didSet{
            tagTypeLabel.hidden = true
        }
    }
    private var tagData:String!
    @IBOutlet weak var focusSwitch: UISwitch!
    
    @IBOutlet weak var showToLinkerSwitch: UISwitch!
    @IBOutlet weak var tagColorView: UIView!{
        didSet{
            tagColorView.layer.cornerRadius = 3
            tagColorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectColor:"))
            update()
        }
    }
    var delegate:UIUserTagEditControllerDelegate!
    var tagModel:UISharelinkTagItemModel!{
        didSet{
            update()
        }
    }
    
    var editMode:UIUserTagEditMode = .New

    @IBAction func changeTagType(sender: AnyObject)
    {
        
    }
    
    func selectColor(_:UITapGestureRecognizer)
    {
        tagColorView.backgroundColor = UIColor.getRandomTextColor()
    }
    
    func update()
    {
        if tagNameLabel != nil
        {
            tagNameLabel.text = tagModel.tag.getEditingName()
        }
        if tagColorView != nil
        {
            tagColorView.backgroundColor = UIColor(hexString: tagModel.tag.tagColor)
        }
        if focusSwitch != nil
        {
            focusSwitch.on = tagModel.tag.isFocus == "true"
        }
    }
    
    @IBAction func save(sender: AnyObject)
    {
        if String.isNullOrWhiteSpace(tagNameLabel.text)
        {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("TAG_NAME_NULL_ERR", comment: ""), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        tagModel.tag.tagName = tagNameLabel.text
        tagModel.tag.tagColor = tagColorView.backgroundColor?.toHexString()
        tagModel.tag.isFocus = focusSwitch.on ? "true":"false"
        tagModel.tag.data = tagData ?? tagModel.tag.tagName;
        tagModel.tag.showToLinkers = showToLinkerSwitch.on ? "true":"false"
        tagModel.tag.type = SharelinkTagConstant.TAG_TYPE_KEYWORD
        if let saveHandler = delegate?.tagEditControllerSave
        {
            saveHandler(tagModel,sender: self)
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
    
    static func instanceFromStoryBoard() -> UIUserTagEditController
    {
        return instanceFromStoryBoard("Component", identifier: "userTagEditController") as! UIUserTagEditController
    }
    
}