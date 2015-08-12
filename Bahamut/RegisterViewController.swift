//
//  RegisterViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController,UITextFieldDelegate
{
    private struct Constants
    {
        static let SegueNextToProfile:String = "Next To Profile"
    }
    @IBOutlet weak var usernameCheckImage: UIImageView!{didSet{usernameCheckImage.hidden = true}}
    @IBOutlet weak var passwordCheckImage: UIImageView!{didSet{passwordCheckImage.hidden = true}}
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    private weak var accountService:AccountService!
    private weak var userService:UserService!
    
    override func viewDidLoad() {
        accountService = ServiceContainer.getService(AccountService)
        userService = ServiceContainer.getService(UserService)
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    func textFieldDidEndEditing(textField: UITextField)
    {
        switch textField
        {
            case usernameTextField:checkUserName()
            default:break
        }
    }
    
    @IBAction func signUp()
    {
        let (isRegularUsername,msg) = TestStringHelper.isRegularUserName(usernameTextField!.text)
        let (isRegularPsw,pmsg) = TestStringHelper.isRegularPassword(passwordTextField!.text)
        if isRegularUsername && isRegularPsw
        {
            view.makeToastActivityWithMessage(message: "Registing")
            signupButton.enabled = false
            accountService.registAccount(usernameTextField!.text, password: passwordTextField.text, registCallback: { (accountId, userId, token,sharelinkApiServer,fileApiServer, error) -> Void in
                self.view.hideToastActivity()
                self.signupButton.enabled = true
                if error == nil
                {
                    ShareLinkSDK.sharedInstance.reuse(userId, token: token, shareLinkApiServer: sharelinkApiServer, fileApiServer: fileApiServer)
                    self.performSegueWithIdentifier(Constants.SegueNextToProfile, sender: self)
                }else{
                    self.view.makeToast(message: error)
                }
                
            })
        }else if isRegularUsername
        {
            view.makeToast(message: pmsg)
        }else
        {
            view.makeToast(message: msg)
        }
    }
    
    func checkUserName()
    {
        let (isRegular,msg) = TestStringHelper.isRegularUserName(usernameTextField!.text)
        usernameCheckImage.hidden = !isRegular
        if isRegular
        {
            userService.checkUsernameAvailable(usernameTextField!.text){
                isAvailable,msg in
                self.usernameCheckImage.hidden = !isAvailable
                if !isAvailable
                {
                    self.view.makeToast(message: msg)
                }
            }
        }else
        {
            view.makeToast(message: msg)
        }
    }
    
    func checkPassword()
    {
        let (isRegular,msg) = TestStringHelper.isRegularPassword(passwordTextField!.text)
        if isRegular
        {
            passwordCheckImage!.hidden = true
        }else
        {
            passwordCheckImage!.hidden = false
        }
    }
}
