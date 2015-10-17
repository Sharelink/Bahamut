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
        myQRImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showActionSheet:"))
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
        alert.addAction(UIAlertAction(title: "Save QRCode To Album", style: .Destructive) { _ in
            self.saveQRImageToAlbum()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
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