//
//  ScanQRViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

protocol QRStringDelegate
{
    func QRdealString(sender:ScanQRViewController,qrString:String)
}

class ScanQRViewController: UIViewController,UIPopoverPresentationControllerDelegate
{
    var delegate:QRStringDelegate!
    private let scanner = QRCode()
    
    @IBOutlet weak var addMoreFriendsButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanner.prepareScan(view) { (stringValue) -> () in
            if let d = self.delegate
            {
                d.QRdealString(self,qrString: stringValue)
            }
        }
        scanner.scanFrame = view.bounds
    }
    
    func startScan()
    {
        scanner.startScan()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showAddMoreFriends"
        {
            if let sg = segue as? UIStoryboardPopoverSegue
            {
                sg.destinationViewController.preferredContentSize = CGSizeMake(128, 200)
                sg.destinationViewController.popoverPresentationController?.sourceRect = CGRectMake(0, 0, 128, 200)
                sg.destinationViewController.popoverPresentationController?.delegate = self
                sg.destinationViewController.popoverPresentationController?.permittedArrowDirections = .Down
            }
        }
        
        super.prepareForSegue(segue, sender: sender)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    @IBAction func addMoreFriends(sender: AnyObject)
    {
        let user = ServiceContainer.getService(UserService).myUserModel
        let defaultIconPath = NSBundle.mainBundle().pathForResource("headImage", ofType: "png", inDirectory: "ChatAssets/photo")
        let userHeadIconPath = PersistentManager.sharedInstance.getImageFilePath(user.avatarId)
        let publishContent = ShareSDK.content("\(user.nickName) Invite You Join Sharelink", defaultContent: "Invite You Join Sharelink", image: ShareSDK.imageWithPath(userHeadIconPath ?? defaultIconPath), title: "Sharelink", url: "http://app.sharelink.online", description: nil, mediaType: SSPublishContentMediaTypeApp)
        
        let container = ShareSDK.container()
        container.setIPadContainerWithBarButtonItem(sender as? UIBarButtonItem, arrowDirect: .Down)
        ShareSDK.showShareActionSheet(container, shareList: nil, content: publishContent, statusBarTips: true, authOptions: nil, shareOptions: nil) { (type, state, statusInfo, error, end) -> Void in
            if (state == SSResponseStateSuccess)
                    {
                        NSLog("share success");
                    }
                    else if (state == SSResponseStateFail)
                    {
                        NSLog("share fail:%ld,description:%@", error.errorCode(), error.errorDescription());
                    }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // start scan
        scanner.startScan()
    }
    
    static func instanceFromStoryBoard() -> ScanQRViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "scanQRViewController") as! ScanQRViewController
    }
    
    static func showScanQRViewController(currentNavigationController:UINavigationController,delegate:QRStringDelegate)
    {
        let controller = ScanQRViewController.instanceFromStoryBoard()
        controller.delegate = delegate
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

extension UserService: QRStringDelegate
{
    func QRdealString(sender:ScanQRViewController,qrString: String)
    {
        let userService = ServiceContainer.getService(UserService)
        let userId = userService.getSharelinkerIdFromQRString(qrString)
        if userService.myLinkedUsersMap.keys.contains(userId)
        {
            userService.showUserProfileViewController(sender.navigationController!, userId: userId)
        }else
        {
            userService.askSharelinkForLink(userId){ isSuc in
                sender.view.makeToast(message: "Request sended")
                sender.startScan()
            }
        }
    }
    
    func showScanQRViewController(currentNavigationController:UINavigationController)
    {
        ScanQRViewController.showScanQRViewController(currentNavigationController, delegate: self)
    }
}