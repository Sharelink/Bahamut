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
    @IBOutlet weak var tagColorView: UIView!{
        didSet{
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

    func selectColor(_:UITapGestureRecognizer)
    {
        tagColorView.backgroundColor = UIColor(hex: arc4random())
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
    }
    
    @IBAction func save(sender: AnyObject)
    {
        tagModel.tagModel.tagName = tagNameLabel.text
        tagModel.tagModel.tagColor = tagColorView.backgroundColor?.toHexString()
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