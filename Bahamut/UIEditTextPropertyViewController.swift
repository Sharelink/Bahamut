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

class UIEditTextPropertySet
{
    var isOneLineValue:Bool = true
    var valueRegex:String!
    var illegalValueMessage:String!
    
    var propertyValue:String!
    var propertyLabel:String!
    var propertyIdentifier:String!
}

class UIEditTextPropertyViewController: UIViewController
{

    @IBOutlet weak var propertyValueTextView: UITextView!{
        didSet{
            propertyValueTextView.layer.cornerRadius = 7
            propertyValueTextView.layer.borderWidth = 1
            propertyValueTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }
    @IBOutlet weak var propertyValueTextField: UITextField!
    @IBOutlet weak var propertyNameLabel: UILabel!
    
    var model:UIEditTextPropertySet!
    var delegate:UIEditTextPropertyViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTextValueView()
        propertyNameLabel.text = model?.propertyLabel
    }
    
    private func updateTextValueView()
    {
        propertyValueTextField.text = model?.propertyValue
        propertyValueTextView.text = model?.propertyValue
        propertyValueTextView.hidden = model.isOneLineValue
        propertyValueTextField.hidden = !model.isOneLineValue
    }
    
    private var newPropertyValue:String!{
        get{
            if model.isOneLineValue
            {
                return propertyValueTextField.text
            }else{
                return propertyValueTextView.text
            }
        }
        set{
            if model.isOneLineValue
            {
                propertyValueTextField.text = newValue
            }else{
                propertyValueTextView.text = newValue
            }
        }
    }
    
    @IBAction func save(sender: AnyObject)
    {
        if delegate != nil
        {
            if model.valueRegex != nil
            {
                if String.isNullOrEmpty(propertyValueTextField.text) || !(propertyValueTextField.text! =~ model.valueRegex)
                {
                    self.view.makeToast(message: model.illegalValueMessage ?? "Illegal Value!")
                    return
                }
            }
            delegate!.editPropertySave(model.propertyIdentifier,newValue: newPropertyValue)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    static func showEditPropertyViewController(currentNavigationController:UINavigationController,propertySet:UIEditTextPropertySet,controllerTitle:String,delegate:UIEditTextPropertyViewControllerDelegate)
    {
        let controller = instanceFromStoryBoard()
        controller.title = controllerTitle
        controller.model = propertySet
        controller.delegate = delegate
        currentNavigationController.pushViewController(controller, animated: true)
    }
    
    static func instanceFromStoryBoard() -> UIEditTextPropertyViewController
    {
        return instanceFromStoryBoard("Component", identifier: "editTextPropertyViewController") as! UIEditTextPropertyViewController
    }
    
}
