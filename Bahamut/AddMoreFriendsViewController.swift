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
        user = ServiceContainer.getService(UserService).myUserModel
        defaultIconPath = NSBundle.mainBundle().pathForResource("headImage", ofType: "png", inDirectory: "ChatAssets/photo")
        userHeadIconPath = PersistentManager.sharedInstance.getImageFilePath(user.avatarId)
    }
    
    var user:ShareLinkUser!
    var defaultIconPath:String!
    var userHeadIconPath:String!
    
    @IBAction func addContact(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            let appIconPath = self.userHeadIconPath ?? self.defaultIconPath
            let _ = ShareSDK.content("SMS", defaultContent: "SMS", image: ShareSDK.imageWithPath(appIconPath), title: "Sharelink", url: "", description: "Invite You Join Sharelink", mediaType: SSPublishContentMediaTypeText)
        }
        
    }
    
    @IBAction func addWeChat(sender: AnyObject) {
        let publishContent = ShareSDK.content("\(self.user.nickName) Invite You Join Sharelink", defaultContent: "Invite You Join Sharelink", image: ShareSDK.imageWithPath(self.userHeadIconPath ?? self.defaultIconPath), title: "Sharelink", url: "", description: nil, mediaType: SSPublishContentMediaTypeApp)
        self.dismissViewControllerAnimated(true) { () -> Void in
            
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
