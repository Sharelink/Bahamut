//
//  ToastHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

func getPresentedViewController() -> UIViewController
{
    let rootVc = UIApplication.sharedApplication().keyWindow?.rootViewController
    let topVc = rootVc
    if let vc = topVc?.presentedViewController
    {
        return vc
    }
    return topVc ?? rootVc ?? UIApplication.sharedApplication().delegate!.window!!.rootViewController!
}

var toastActivityMap = [UIViewController:MBProgressHUD]()
extension UIViewController:MBProgressHUDDelegate
{
    func hideToastActivity()
    {
        if let hud = toastActivityMap.removeValueForKey(self)
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                hud.hide(true)
            })
            
        }
    }
    
    public func hudWasHidden(hud: MBProgressHUD!) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            hud.removeFromSuperview()
        })
        
    }
    
    func makeToastActivity()
    {
        let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
        vc.makeToastActivityWithMessage("", message: "")
    }
    
    func makeToastActivityWithMessage(title:String!,message:String!)
    {
        let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
        let vcView = vc.navigationController?.view ?? vc.view
        let HUD = MBProgressHUD(view: vcView)
        HUD.delegate = vc
        HUD.labelText = title
        HUD.detailsLabelText = message
        HUD.square = true
        HUD.show(true)
        toastActivityMap[vc] = HUD
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            vcView!.addSubview(HUD)
        })
        
    }
    
    func showToast(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc:UIViewController = getPresentedViewController()
            let vcView = vc.navigationController?.view ?? vc.view
            let hud = MBProgressHUD.showHUDAddedTo(vcView, animated: true)
            // Configure for text only and offset down
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = msg
            hud.margin = 10;
            hud.delegate = vc
            hud.removeFromSuperViewOnHide = true
            hud.hide(true, afterDelay: 1)
        }
        
    }
    
    func showCrossMark(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
            let vcView = vc.navigationController?.view ?? vc.view
            let HUD = MBProgressHUD(view: vcView)
            vcView!.addSubview(HUD)
            
            HUD.customView = UIImageView(image: UIImage(named: "Crossmark"))
            
            // Set custom view mode
            HUD.mode = MBProgressHUDMode.CustomView
            
            HUD.delegate = vc
            HUD.labelText = msg
            HUD.square = true
            HUD.show(true)
            HUD.hide(true, afterDelay: 1)
        }
    }
    
    func showCheckMark(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
            let vcView = vc.navigationController?.view ?? vc.view
            let HUD = MBProgressHUD(view: vcView)
            self.navigationController?.view.addSubview(HUD)
            
            HUD.customView = UIImageView(image: UIImage(named: "Checkmark"))
            
            // Set custom view mode
            HUD.mode = MBProgressHUDMode.CustomView
            
            HUD.delegate = vc
            HUD.labelText = msg
            HUD.square = true
            HUD.show(true)
            HUD.hide(true, afterDelay: 1)
        }
    }
    
    func showAlert(presentRootController:UIViewController,alertController:UIAlertController)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            presentRootController.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}