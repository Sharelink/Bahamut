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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("MyQRCode")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("MyQRCode")
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