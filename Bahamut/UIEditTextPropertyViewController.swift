//
//  UIEditTextPropertyViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

protocol UIEditTextPropertyViewControllerDelegate
{
    func editPropertySave(propertyIdentifier:String!,newValue:String!)
}

class UIEditTextPropertyViewController: UIViewController
{

    @IBOutlet weak var propertyValueTextField: UITextField!{
        didSet{
            propertyValueTextField.text = propertyValue
        }
    }
    @IBOutlet weak var propertyNameLabel: UILabel!{
        didSet{
            propertyNameLabel.text = propertyLabel
        }
    }
    var propertyValue:String!
    var propertyLabel:String!
    var propertyIdentifier:String!
    var delegate:UIEditTextPropertyViewControllerDelegate!
    
    @IBAction func save(sender: AnyObject)
    {
        if delegate != nil
        {
            delegate!.editPropertySave(propertyIdentifier,newValue: propertyValueTextField.text)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    static func showEditPropertyViewController(currentNavigationController:UINavigationController,propertyIdentifier:String,propertyValue:String,propertyLabel:String,title:String,delegate:UIEditTextPropertyViewControllerDelegate)
    {
        let controller = instanceFromStoryBoard()
        controller.title = title
        controller.propertyValue = propertyValue
        controller.propertyLabel = propertyLabel
        controller.propertyIdentifier = propertyIdentifier
        controller.delegate = delegate
        currentNavigationController.pushViewController(controller, animated: true)
    }
    
    static func instanceFromStoryBoard() -> UIEditTextPropertyViewController
    {
        return instanceFromStoryBoard("Component", identifier: "editTextPropertyViewController") as! UIEditTextPropertyViewController
    }
    
}
