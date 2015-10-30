//
//  MyQRViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class MyQRViewController: UIViewController
{
    var qrString:String!
    var avatarImage:UIImage!
    @IBOutlet weak var myQRImageView: UIImageView!
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        myQRImageView.image = QRCode.generateImage(qrString, avatarImage: nil, avatarScale: 0.3)
        myQRImageView.userInteractionEnabled = true
        //myQRImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showActionSheet:"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ServiceContainer.getService(UserService).addObserver(self, selector: "onNewLink:", name: UserService.linkMessageUpdated, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ServiceContainer.getService(UserService).removeObserver(self)
    }
    
    func onNewLink(a:NSNotification)
    {
        if let userInfo = a.userInfo
        {
            if let lm = userInfo[UserServiceFirstLinkMessage] as? LinkMessage
            {
                if lm.type == LinkMessageType.AskLink.rawValue
                {
                    ServiceContainer.getService(UserService).showLinkConfirmViewController(self.navigationController!, linkMessage: lm)
                }
            }
        }
    }
    
    func showActionSheet(_:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: "Save QRCode", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Share QRCode", style: .Destructive) { _ in
            self.shareQrCode()
            })
        alert.addAction(UIAlertAction(title: "Save QRCode To Album", style: .Destructive) { _ in
            self.saveQRImageToAlbum()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func shareQrCode()
    {
        let userService = ServiceContainer.getService(UserService)
        let linkMeCmd = userService.generateSharelinkLinkMeCmd()
        let url = "\(BahamutConfig.sharelinkOuterExecutorUrlPrefix)\(linkMeCmd)"
        
        if let img = QRCode.generateImage(url, avatarImage: nil)
        {
            let imgData = UIImageJPEGRepresentation(img, 1.0)
            
            let contentMsg = "Scan this QRCode to link with \(userService.myUserModel.nickName) on Sharelink"
            let title = "Sharelink"
            
            let contentWithUrl = "\(contentMsg)\n\(url)"
            
            let img = ShareSDK.imageWithData(imgData, fileName: nil, mimeType: nil)
            
            let publishContent = ShareSDK.content(contentWithUrl, defaultContent: nil, image: img, title: title, url: url, description: nil, mediaType: SSPublishContentMediaTypeImage)
            
            let container = ShareSDK.container()
            container.setIPadContainerWithView(self.view, arrowDirect: .Down)
            container.setIPhoneContainerWithViewController(self)
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
    }
    
    func saveQRImageToAlbum()
    {
        let cgImage = CIContext().createCGImage((myQRImageView.image?.CIImage)!, fromRect: (myQRImageView.image?.CIImage?.extent)!)
        let saveImage = UIImage(CGImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(saveImage, self, nil, nil)
        self.view.makeToast(message: "Saved")
    }
    
    static func instanceFromStoryBoard() -> MyQRViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "myQRViewController") as! MyQRViewController
    }
    
}

extension UserService
{
    func showMyQRViewController(currentNavigationController:UINavigationController,sharelinkUserId:String,avataImage:UIImage!)
    {
        let controller = MyQRViewController.instanceFromStoryBoard()
        controller.avatarImage = avataImage
        controller.qrString = ServiceContainer.getService(UserService).generateSharelinkerQrString()
        currentNavigationController.pushViewController(controller, animated: true)
    }
}