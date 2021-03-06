//
//  AboutViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController,MFMailComposeViewControllerDelegate{

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("AboutView")
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("AboutView")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.changeNavigationBarColor()
    }
    
    @IBAction func showInAppStore(sender: AnyObject)
    {
        let url = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=\(SharelinkConfig.bahamutConfig.appStoreId)"
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }

    @IBAction func mailToBahamutSharelink(sender: AnyObject) {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject("Sharelink Feedback")
        mail.setToRecipients([SharelinkConfig.bahamutConfig.bahamutAppEmail])
        self.presentViewController(mail, animated: true, completion: nil)

    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    static func showAbout(currentViewController:UIViewController)
    {
        let controller = instanceFromStoryBoard()
        if let nvController = currentViewController.navigationController
        {
            nvController.pushViewController(controller, animated: true)
        }
    }
    
    static func instanceFromStoryBoard() -> AboutViewController
    {
        return instanceFromStoryBoard("Component", identifier: "aboutViewController",bundle: Sharelink.mainBundle()) as! AboutViewController
    }
}
