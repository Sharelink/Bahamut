//
//  SignInViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController
{
    struct SegueConstants {
        static let ShowMainView = "ShowMainView"
    }
    @IBOutlet weak var validateStringTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func signIn()
    {
        let service = ServiceContainer.getService(AccountService)
        
        let resultValidateText = TestStringHelper.isRegularUserName(validateStringTextField.text)
        let resultPsw = TestStringHelper.isRegularPassword(passwordTextField.text)
        if !resultValidateText.isRegular
        {
            view.makeToast(message: resultValidateText.message)
        }else if !resultPsw.isRegular
        {
            view.makeToast(message: resultPsw.message)
        }else
        {
            view.makeToastActivityWithMessage(message: "authenticating")
            service.login(validateStringTextField.text, password: passwordTextField.text, loginCallback: signCallback)
        }
    }
    
    func signCallback(loginSuc:Bool,msg:String!)
    {
        view.hideToastActivity()
        if loginSuc
        {
            ServiceContainer.getService(ShareService).test()
            let service = ServiceContainer.getService(UserService)
            view.makeToastActivityWithMessage(message: "Refreshing LinkedUsers")
            service.refreshMyLinkedUsers({ (isSuc, msg) -> Void in
                self.view.hideToastActivity()
                if isSuc
                {
                    self.performSegueWithIdentifier(SegueConstants.ShowMainView, sender: self)
                }else
                {
                    self.view.makeToast(message: msg)
                }
            })
        }else
        {
            self.view.makeToast(message: msg)
        }
    }
}
