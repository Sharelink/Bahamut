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

extension UIApplication
{
    static var currentShowingViewController:UIViewController{
        var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while topVC?.presentedViewController != nil {
            topVC = topVC?.presentedViewController
        }
        if let tvc = topVC as? UITabBarController
        {
            if let topVC = tvc.selectedViewController
            {
                return topVC
            }
        }
        return topVC!
    }
    
    static var currentNavigationController:UINavigationController?{
        let svc = currentShowingViewController
        return svc as? UINavigationController ?? svc.navigationController
    }
}

typealias HudHiddenCompletedHandler = ()->Void

var hudCompletionHandler = [MBProgressHUD:HudHiddenCompletedHandler]()

extension MBProgressHUD
{
    func hideAsync(animated:Bool)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.hide(animated)
        }
    }
}

extension UIViewController:MBProgressHUDDelegate
{
    public func hudWasHidden(hud: MBProgressHUD!) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            hud.removeFromSuperview()
            if let handler = hudCompletionHandler.removeValueForKey(hud)
            {
                handler()
            }
        })
        
    }
    
    func showActivityHud(completionHandler:HudHiddenCompletedHandler! = nil)-> MBProgressHUD
    {
        return showActivityHudWithMessage("", message: "",completionHandler: completionHandler)
    }
    
    func showActivityHudWithMessage(title:String!,message:String!,completionHandler:HudHiddenCompletedHandler! = nil) -> MBProgressHUD
    {
        let vc = UIApplication.currentShowingViewController
        let vcView = vc.view ?? vc.navigationController?.view
        let HUD = MBProgressHUD(view: vcView)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            HUD.delegate = vc
            HUD.labelText = title
            HUD.detailsLabelText = message
            HUD.removeFromSuperViewOnHide = true
            HUD.square = true
            HUD.show(true)
            vcView!.addSubview(HUD)
        })
        return HUD
    }
    
    func playToast(msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc = UIApplication.currentShowingViewController
            let vcView = vc.view ?? vc.navigationController?.view
            
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
    
    func playCrossMark(msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc = UIApplication.currentShowingViewController
            let vcView = vc.view ?? vc.navigationController?.view
            
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
    
    func playCheckMark(msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let vc = UIApplication.currentShowingViewController
            let vcView = vc.view ?? vc.navigationController?.view
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