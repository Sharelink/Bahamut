//
//  ChangePasswordViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/27.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
class ChangePasswordViewController: UIViewController
{
    
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBAction func changePassword(sender: AnyObject) {
        let newPsw = newPasswordTextField.text ?? ""
        let oldPsw = oldPasswordTextField.text ?? ""
        if String.isNullOrWhiteSpace(oldPsw)
        {
            self.showAlert(NSLocalizedString("OLD_PSW_NULL", comment: ""), msg: nil)
            return
        }else if newPsw =~ "^[A-Za-z0-9_\\@\\!\\#\\$\\%\\^\\&\\*\\.\\~]{6,23}$"
        {
            showAlert(NSLocalizedString("CONFIRM_PSW", comment: "Change Password To"), msg: newPsw, actions: [
                UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: .Default, handler: { (action) -> Void in
                    self.makeToastActivity()
                    ServiceContainer.getService(AccountService).changePassword(oldPsw, newPsw: newPsw) { (isSuc) -> Void in
                        self.hideToastActivity()
                        if isSuc
                        {
                            self.showAlert(NSLocalizedString("CHG_PSW_SUC", comment: ""), msg: nil)
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        }else
                        {
                            self.showAlert(NSLocalizedString("CHG_PSW_FAIL", comment: ""), msg: nil)
                        }
                    }
                }),
                UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel, handler: nil)
                ])
            
        }else
        {
            self.showAlert(NSLocalizedString("WRONG_PSW_FORMAT", comment: ""), msg: NSLocalizedString("PSW_FORMAT", comment: ""))
        }
    }
    
    static func instanceFromStoryBoard()->ChangePasswordViewController{
        return instanceFromStoryBoard("UserAccount", identifier: "ChangePasswordViewController") as! ChangePasswordViewController
    }

}