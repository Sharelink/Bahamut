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
import SharelinkSDK

protocol QRStringDelegate
{
    func QRdealString(sender:ScanQRViewController,qrString:String)
}

class ScanQRViewController: UIViewController,UIPopoverPresentationControllerDelegate
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
        if SharelinkCmd.isSharelinkCmdUrl(qrString)
        {
            sender.dismissViewControllerAnimated(true, completion: { () -> Void in
                let cmd = SharelinkCmd.getCmdFromUrl(qrString)
                SharelinkCmdManager.sharedInstance.handleSharelinkCmdWithMainQueue(cmd)
            })
        }else if qrString.hasBegin("http://") || qrString.hasBegin("https://")
        {
            if qrString.hasPrefix(BahamutConfig.sharelinkOuterExecutorUrlPrefix)
            {
                let cmdEncoded = qrString.stringByReplacingOccurrencesOfString(BahamutConfig.sharelinkOuterExecutorUrlPrefix, withString: "")
                if let cmd = SharelinkCmd.decodeSharelinkCmd(cmdEncoded)
                {
                    sender.dismissViewControllerAnimated(true, completion: { () -> Void in
                        SharelinkCmdManager.sharedInstance.handleSharelinkCmdWithMainQueue(cmd)
                    })
                }
            }else
            {
                let controller = sender.navigationController
                sender.dismissViewControllerAnimated(true, completion: { () -> Void in
                    SimpleBrowser.openUrl(controller!, url: qrString)
                })
            }
        }

    }
    
    func showScanQRViewController(currentNavigationController:UINavigationController)
    {
        ScanQRViewController.showScanQRViewController(currentNavigationController, delegate: self)
    }
}