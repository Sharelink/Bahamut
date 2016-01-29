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

typealias HudHiddenCompletedHandler = ()->Void

var toastActivityMap = [UIViewController:MBProgressHUD]()
var hudCompletionHandler = [MBProgressHUD:HudHiddenCompletedHandler]()

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
            if let handler = hudCompletionHandler.removeValueForKey(hud)
            {
                handler()
            }
        })
        
    }
    
    func makeToastActivity(completionHandler:HudHiddenCompletedHandler! = nil)
    {
        let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
        vc.makeToastActivityWithMessage("", message: "",completionHandler: completionHandler)
    }
    
    func makeToastActivityWithMessage(title:String!,message:String!,completionHandler:HudHiddenCompletedHandler! = nil)
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
    
    func showToast(msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
            let vcView = vc.navigationController?.view ?? vc.view
            
            let hud = MBProgressHUD.showHUDAddedTo(vcView, animated: true)
            // Configure for text only and offset down
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = msg
            hud.margin = 10;
            hud.delegate = vc
            if let handler = completionHandler
            {
                hudCompletionHandler[hud] = handler
            }
            hud.removeFromSuperViewOnHide = true
            hud.show(true)
            hud.hide(true, afterDelay: 1)
        }
        
    }
    
    func showCrossMark(msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
            let vcView = vc.navigationController?.view ?? vc.view
            let hud = MBProgressHUD(view: vcView)
            vcView!.addSubview(hud)
            
            hud.customView = UIImageView(image: UIImage(named: "Crossmark"))
            
            // Set custom view mode
            hud.mode = MBProgressHUDMode.CustomView
            hud.removeFromSuperViewOnHide = true
            hud.delegate = vc
            hud.labelText = msg
            hud.square = true
            if let handler = completionHandler
            {
                hudCompletionHandler[hud] = handler
            }
            hud.show(true)
            hud.hide(true, afterDelay: 1)
        }
    }
    
    func showCheckMark(msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc:UIViewController! = self.navigationController == nil ? getPresentedViewController() : self
            let vcView = vc.navigationController?.view ?? vc.view
            let hud = MBProgressHUD(view: vcView)
            self.navigationController?.view.addSubview(hud)
            
            hud.customView = UIImageView(image: UIImage(named: "Checkmark"))
            hud.removeFromSuperViewOnHide = true
            // Set custom view mode
            hud.mode = MBProgressHUDMode.CustomView
            
            hud.delegate = vc
            hud.labelText = msg
            hud.square = true
            if let handler = completionHandler
            {
                hudCompletionHandler[hud] = handler
            }
            hud.show(true)
            hud.hide(true, afterDelay: 1)
        }
    }
    
    func showAlert(presentRootController:UIViewController,alertController:UIAlertController)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            presentRootController.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}