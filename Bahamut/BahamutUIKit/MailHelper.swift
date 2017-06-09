//
//  MailHelper.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/28.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import MessageUI

class MailHelper:NSObject,MFMailComposeViewControllerDelegate {
    
    static let instance:MailHelper = {
        return MailHelper()
    }()
    
    static func showMail(vc:UIViewController,subject:String,recipients:[String]) -> Bool{
        if MFMailComposeViewController.canSendMail(){
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = MailHelper.instance
            mail.setSubject(subject)
            mail.setToRecipients(recipients)
            vc.present(mail, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
