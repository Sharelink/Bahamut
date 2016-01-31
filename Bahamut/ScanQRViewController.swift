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

class ScanQRViewController: UIViewController,UIPopoverPresentationControllerDelegate
{
    var delegate:QRStringDelegate!
    private let scanner = QRCode()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("ScanQRCode")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("ScanQRCode")
    }
    
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // start scan
        scanner.startScan()
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

    
    static func instanceFromStoryBoard() -> ScanQRViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "scanQRViewController",bundle: Sharelink.mainBundle()) as! ScanQRViewController
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
            sender.navigationController?.popViewControllerAnimated(true)
            let cmd = SharelinkCmd.getCmdFromUrl(qrString)
            SharelinkCmdManager.sharedInstance.handleSharelinkCmdWithMainQueue(cmd)
        }else if qrString.hasBegin("http://") || qrString.hasBegin("https://")
        {
            if qrString.hasPrefix(SharelinkConfig.bahamutConfig.sharelinkOuterExecutorUrlPrefix)
            {
                let cmdEncoded = qrString.stringByReplacingOccurrencesOfString(SharelinkConfig.bahamutConfig.sharelinkOuterExecutorUrlPrefix, withString: "")
                if let cmd = SharelinkCmd.decodeSharelinkCmd(cmdEncoded)
                    
                    
                {
                    sender.navigationController?.popViewControllerAnimated(true)
                    SharelinkCmdManager.sharedInstance.handleSharelinkCmdWithMainQueue(cmd)
                }
            }else
            {
                sender.navigationController?.popViewControllerAnimated(false)
                dispatch_after(1000*2, dispatch_get_main_queue(), { () -> Void in
                    if let navc = UIApplication.currentNavigationController
                    {
                        SimpleBrowser.openUrl(navc, url: qrString)
                    }
                })
            }
        }

    }
    
    func showScanQRViewController(currentNavigationController:UINavigationController)
    {
        ScanQRViewController.showScanQRViewController(currentNavigationController, delegate: self)
    }
}