//
//  UIUserTagEditController.swift
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
            tagNameLabel.text = tagModel.tagModel.tagName
        }
        if tagColorView != nil
        {
            tagColorView.backgroundColor = UIColor(hexString: tagModel.tagModel.tagColor)
        }
        if focusSwitch != nil
        {
            focusSwitch.on = tagModel.tagModel.isFocus == "true"
        }
    }
    
    @IBAction func save(sender: AnyObject)
    {
        tagModel.tagModel.tagName = tagNameLabel.text
        tagModel.tagModel.tagColor = tagColorView.backgroundColor?.toHexString()
        tagModel.tagModel.isFocus = focusSwitch.on ? "true":"false"
        tagModel.tagModel.data = tagData ?? tagModel.tagModel.tagName; //tagData is nil ,is's a text tag
        tagModel.tagModel.showToLinkers = showToLinkerSwitch.on ? "true":"false"
        tagModel.tagModel.type = SharelinkTagConstant.TAG_TYPE_KEYWORD
        if let saveHandler = delegate?.tagEditControllerSave
        {
            saveHandler(tagModel,sender: self)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    static func instanceFromStoryBoard() -> UIUserTagEditController
    {
        return instanceFromStoryBoard("Component", identifier: "userTagEditController") as! UIUserTagEditController
    }
    
}