//
//  ScanQRViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

protocol QRStringDelegate
{
    func QRdealString(sender:ScanQRViewController,qrString:String)
}

class ScanQRViewController: UIViewController
{
    var delegate:QRStringDelegate!
    private let scanner = QRCode()
    
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
        let accountId = ServiceContainer.getService(AccountService).getSharelinkerAccountIdFromQRString(qrString)
        ServiceContainer.getService(UserService).askSharelinkForLink(accountId){ isSuc in
            sender.view.makeToast(message: "Request sended")
            sender.startScan()
        }
    }
    
    func showScanQRViewController(currentNavigationController:UINavigationController)
    {
        ScanQRViewController.showScanQRViewController(currentNavigationController, delegate: self)
    }
}