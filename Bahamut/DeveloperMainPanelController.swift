//
//  DeveloperMainPanelController.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class DeveloperMainPanelController: UIViewController
{
    
    @IBAction func clearAllData(sender: AnyObject)
    {
        PersistentManager.sharedInstance.clearCache()
        PersistentManager.sharedInstance.clearRootDir()
    }
    
    @IBAction func use168Server(sender: AnyObject)
    {
        SharelinkSetting.loginApi = "http://192.168.1.168:8086/Account/AjaxLogin"
        SharelinkSetting.registAccountApi = "http://192.168.1.168:8086/Account/AjaxRegist"
        self.playToast("Change to 168")
    }
    
    @IBAction func use67Server(sender: AnyObject)
    {
        SharelinkSetting.loginApi = "http://192.168.1.67:8086/Account/AjaxLogin"
        SharelinkSetting.registAccountApi = "http://192.168.1.67:8086/Account/AjaxRegist"
        self.playToast("Change to 67")
    }
    
    @IBAction func closePanel(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    @IBAction func useRemoteServer(sender: AnyObject)
    {
        SharelinkSetting.loginApi = "http://auth.sharelink.online:8086/Account/AjaxLogin"
        SharelinkSetting.registAccountApi = "http://auth.sharelink.online:8086/Account/AjaxRegist"
        self.playToast("Change to remote")
    }
    
    private static let idpswHash = "0992369b28f2d4903851f17382cc884a97b6ecaf939fc02063dd113a21ee334e"
    static func isShowDeveloperPanel(controller:UIViewController,id:String,psw: String) -> Bool{
        if "\(id)\(psw)".sha256 == idpswHash
        {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                UserSetting.isAppstoreReviewing = false
                DeveloperMainPanelController.showDeveloperMainPanel(controller)
            }
            return true
        }else
        {
            return false
        }
    }
    
    private static func showDeveloperMainPanel(viewController:UIViewController)
    {
        let controller = instanceFromStoryBoard("DeveloperPanel", identifier: "DeveloperMainPanelController",bundle: Sharelink.mainBundle())
        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.barStyle = viewController.navigationController!.navigationBar.barStyle
        viewController.presentViewController(navController, animated: true) { () -> Void in
            
        }
    }
    
}