//
//  HarmfulFeedbackViewController.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/9.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD

class HarmfulReportViewController: UIViewController,MFMailComposeViewControllerDelegate {

    static let harmfulReportEmail = "sharelink-harmful-report@outlook.com"
    @IBOutlet weak var reporterIdLabel: UILabel!
    @IBOutlet weak var reporterEmailTextField: UITextField!
    @IBOutlet weak var reportTypeLabel: UILabel!
    @IBOutlet weak var reportContentTextView: UITextView!{
        didSet{
            reportContentTextView.layer.cornerRadius = 7
            reportContentTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
            reportContentTextView.layer.borderWidth = 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.changeNavigationBarColor()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelReport(sender: AnyObject) {
        self.dismissViewControllerAnimated(true){}
    }
    
    @IBAction func sendReport(sender: AnyObject) {
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject(reportTypeLabel.text ?? "")
        
        let mailBody = "Reporter Id:\(reporterIdLabel.text!)\n" +
                        (String.isNullOrWhiteSpace(reporterEmailTextField.text) ? "" : "Reporter Email For Reply:\(reporterEmailTextField.text!)\n") +
                        "\nReport Content\n\(reportContentTextView.text)"
        
        mail.setMessageBody(mailBody, isHTML: false)
        mail.setToRecipients([HarmfulReportViewController.harmfulReportEmail])
        self.presentViewController(mail, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result
        {
        case MFMailComposeResultCancelled:
            controller.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.showCrossMark(NSLocalizedString("CANCELED", comment: ""))
            })
            
        case MFMailComposeResultFailed:
            controller.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.showCrossMark(NSLocalizedString("FAILED", comment: ""))
            })
            
        case MFMailComposeResultSent: fallthrough
        case MFMailComposeResultSaved:
            controller.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.showCheckMark(""){
                    self.dismissViewControllerAnimated(true){}
                }
            })
        default:break
        }
    }
    
    static func instanceFromStoryBoard() -> HarmfulReportViewController
    {
        return instanceFromStoryBoard("Component", identifier: "HarmfulReportViewController",bundle: Sharelink.mainBundle) as! HarmfulReportViewController
    }

}
