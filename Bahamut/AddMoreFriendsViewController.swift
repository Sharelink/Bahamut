//
//  AddMoreFriendsViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MBProgressHUD

class AddMoreFriendsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func addContact(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            let appIconPath = PersistentManager.sharedInstance.getImageFilePath("sharelink")
            let _ = ShareSDK.content("SMS", defaultContent: "SMS", image: ShareSDK.imageWithPath(appIconPath), title: "Sharelink", url: "", description: "Invite You Join Sharelink", mediaType: SSPublishContentMediaTypeText)
            ShareSDK.connectSMS()
        }
        
    }
    
    @IBAction func addWeChat(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            let appIconPath = PersistentManager.sharedInstance.getImageFilePath("sharelink")
            let publishContent = ShareSDK.content("WeChat", defaultContent: "WeChat", image: ShareSDK.imageWithPath(appIconPath), title: "Sharelink", url: "", description: "Invite You Join Sharelink", mediaType: SSPublishContentMediaTypeApp)
            ShareSDK.clientShareContent(publishContent, type: ShareTypeWeixiSession, statusBarTips: true) { (type, state, info, err, flag) -> Void in
                if state == SSResponseStateSuccess
                {
                    self.parentViewController?.view.makeToast(message: "Success")
                }else
                {
                    self.parentViewController?.view.makeToast(message: "Failed")
                }
            }
        }
    }
    
    @IBAction func addQQ(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
            let appIconPath = PersistentManager.sharedInstance.getImageFilePath("sharelink")
            let publishContent = ShareSDK.content("QQ", defaultContent: "QQ", image: ShareSDK.imageWithPath(appIconPath), title: "Sharelink", url: "", description: "Invite You Join Sharelink", mediaType: SSPublishContentMediaTypeApp)
            ShareSDK.clientShareContent(publishContent, type: ShareTypeQQ, statusBarTips: true) { (type, state, info, err, flag) -> Void in
                if state == SSResponseStateSuccess
                {
                    self.parentViewController?.view.makeToast(message: "Success")
                }else
                {
                    self.parentViewController?.view.makeToast(message: "Failed")
                }
            }
        }
    }
    
    @IBAction func addWeibo(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            let appIconPath = PersistentManager.sharedInstance.getImageFilePath("sharelink")
            let publishContent = ShareSDK.content("Weibo", defaultContent: "Weibo", image: ShareSDK.imageWithPath(appIconPath), title: "Sharelink", url: "", description: "Invite You Join Sharelink", mediaType: SSPublishContentMediaTypeText)
            ShareSDK.clientShareContent(publishContent, type: ShareTypeSinaWeibo, statusBarTips: true) { (type, state, info, err, flag) -> Void in
                if state == SSResponseStateSuccess
                {
                    self.parentViewController?.view.makeToast(message: "Success")
                }else
                {
                    self.parentViewController?.view.makeToast(message: "Failed")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
