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
    func showUIUserTagEditController(currentNavigationController:UINavigationController)
    {
        let storyBoard = UIStoryboard(name: "Component", bundle: NSBundle.mainBundle())
        let userTagEditController = storyBoard.instantiateViewControllerWithIdentifier("userTagEditController") as! UIUserTagEditController
        currentNavigationController.pushViewController(userTagEditController, animated: true)
    }
}

@objc
protocol UIUserTagEditControllerDelegate
{
    optional func tagEditControllerSave(saveModel:UserTagModel,sender:UIUserTagEditController)
}

enum UIUserTagEditMode
{
    case New
    case Edit
}

class UIUserTagEditController: UIViewController
{
    @IBOutlet weak var tagNameLabel: UITextField!
    var delegate:UIUserTagEditControllerDelegate!
    var tagModel:UserTagModel!{
        didSet{
            
        }
    }
    var editMode:UIUserTagEditMode = .New
    {
        didSet{
            
        }
    }

    @IBAction func save(sender: AnyObject)
    {
        if let saveHandler = delegate?.tagEditControllerSave
        {
            saveHandler(tagModel,sender: self)
        }
    }
    
}