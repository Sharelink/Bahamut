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

let ALERT_ACTION_OK = UIAlertAction(title: "OK".localizedString(), style:.Cancel, handler: nil)
let ALERT_ACTION_I_SEE = UIAlertAction(title: "I_SEE".localizedString(), style:.Cancel, handler: nil)
let ALERT_ACTION_CANCEL = UIAlertAction(title: "CANCEL".localizedString(), style:.Cancel, handler: nil)

//MARK: extension show alert
extension UIViewController
{
    
    func showAlert(title:String!,msg:String!,actions:[UIAlertAction] = [UIAlertAction(title: "OK".localizedString(), style:.Cancel, handler: nil)])
    {
        let controller = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        for ac in actions
        {
            controller.addAction(ac)
        }
        showAlert(controller)
    }
    
    func showAlert(alertController:UIAlertController)
    {
        showAlert(UIApplication.currentShowingViewController, alertController: alertController)
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
    
    func showActivityHudWithMessage(title:String!,message:String!,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil) -> MBProgressHUD
    {
        let vc = UIApplication.currentShowingViewController
        let vcView = vc.view ?? vc.navigationController?.view
        let HUD = MBProgressHUD(view: vcView)
        HUD.delegate = vc
        HUD.labelText = title
        HUD.detailsLabelText = message
        HUD.removeFromSuperViewOnHide = true
        HUD.square = true
        if async{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vcView!.addSubview(HUD)
                HUD.show(true)
            })
        }else{
            vcView!.addSubview(HUD)
            HUD.show(true)
        }
        return HUD
    }
    
    func playToast(msg:String,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil)
    {
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
        if async
        {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                hud.show(true)
                hud.hide(true, afterDelay: 2)
            }
        }else
        {
            hud.show(true)
            hud.hide(true, afterDelay: 2)
        }
        
    }
    
    func playCrossMark(msg:String,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        playImageMark(msg, image: UIImage(named: "Crossmark")!, async: async, completionHandler: completionHandler)
    }
    
    func playCheckMark(msg:String,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        playImageMark(msg, image: UIImage(named: "Checkmark")!, async: async, completionHandler: completionHandler)
    }
    
    func playImageMark(msg:String,image:UIImage,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil){
        let vc = UIApplication.currentShowingViewController
        let vcView = vc.view ?? vc.navigationController?.view
        let hud = MBProgressHUD(view: vcView)
        vcView!.addSubview(hud)
        
        hud.customView = UIImageView(image: image)
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
        if async
        {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                hud.show(true)
                hud.hide(true, afterDelay: 2)
            }
        }else
        {
            hud.show(true)
            hud.hide(true, afterDelay: 2)
        }
    }
    
    func showAlert(presentRootController:UIViewController,alertController:UIAlertController)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            presentRootController.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}