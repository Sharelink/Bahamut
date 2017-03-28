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
        var topVC = UIApplication.shared.keyWindow?.rootViewController
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

var ALERT_ACTION_OK:UIAlertAction{
    return UIAlertAction(title: "OK".localizedString(), style:.cancel, handler: nil)
}

var ALERT_ACTION_I_SEE:UIAlertAction{
    return UIAlertAction(title: "I_SEE".localizedString(), style:.cancel, handler: nil)
}

var ALERT_ACTION_CANCEL:UIAlertAction{
    return UIAlertAction(title: "CANCEL".localizedString(), style:.cancel, handler: nil)
}

//MARK: extension show alert
extension UIViewController
{
    
    func showAlert(_ title:String!,msg:String!,actions:[UIAlertAction] = [UIAlertAction(title: "OK".localizedString(), style:.cancel, handler: nil)])
    {
        let controller = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        for ac in actions
        {
            controller.addAction(ac)
        }
        showAlert(controller)
    }
    
    func showAlert(_ alertController:UIAlertController)
    {
        showAlert(UIApplication.currentShowingViewController, alertController: alertController)
    }
}

extension UIAlertController{
    static func create(title:String? = nil,message:String? = nil,preferredStyle:UIAlertControllerStyle = .alert) -> UIAlertController {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        }else{
            return UIAlertController(title: title, message: message, preferredStyle: .alert)
        }
    }
}

typealias HudHiddenCompletedHandler = ()->Void

var hudCompletionHandler = [MBProgressHUD:HudHiddenCompletedHandler]()

extension MBProgressHUD
{
    func hideAsync(_ animated:Bool)
    {
        DispatchQueue.main.async { () -> Void in
            self.hide(animated: animated)
        }
    }
}

extension UIViewController:MBProgressHUDDelegate
{
    public func hudWasHidden(_ hud: MBProgressHUD) {
        DispatchQueue.main.async(execute: { () -> Void in
            hud.removeFromSuperview()
            if let handler = hudCompletionHandler.removeValue(forKey: hud)
            {
                handler()
            }
        })
        
    }
    
    func showActivityHud(_ completionHandler:HudHiddenCompletedHandler! = nil)-> MBProgressHUD
    {
        return showActivityHudWithMessage("", message: "",completionHandler: completionHandler)
    }
    
    func showActivityHudWithMessage(_ title:String!,message:String!,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil) -> MBProgressHUD
    {
        let vc = UIApplication.currentShowingViewController
        let vcView = vc.view ?? vc.navigationController?.view
        let HUD = MBProgressHUD(view: vcView!)
        HUD.delegate = vc
        HUD.label.text = title
        HUD.detailsLabel.text = message
        HUD.removeFromSuperViewOnHide = true
        HUD.isSquare = true
        if async{
            DispatchQueue.main.async(execute: { () -> Void in
                vcView!.addSubview(HUD)
                HUD.show(animated: true)
            })
        }else{
            vcView!.addSubview(HUD)
            HUD.show(animated: true)
        }
        return HUD
    }
    
    func playToast(_ msg:String,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        let vc = UIApplication.currentShowingViewController
        let vcView = vc.view ?? vc.navigationController?.view
        DispatchQueue.main.async { () -> Void in
            let hud = MBProgressHUD.showAdded(to: vcView!, animated: true)
            // Configure for text only and offset down
            hud.mode = MBProgressHUDMode.text
            hud.label.text = msg
            hud.margin = 10;
            hud.delegate = vc
            if let handler = completionHandler
            {
                hudCompletionHandler[hud] = handler
            }
            hud.removeFromSuperViewOnHide = true
            hud.show(animated: true)
            hud.hide(animated: true, afterDelay: 2)
        }
    }
    
    func playCrossMark(_ msg:String? = "",async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        playImageMark(msg, image: UIImage(named: "bahamut_crossmark")!, async: async, completionHandler: completionHandler)
    }
    
    func playCheckMark(_ msg:String? = "",async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil)
    {
        playImageMark(msg, image: UIImage(named: "bahamut_checkmark")!, async: async, completionHandler: completionHandler)
    }
    
    fileprivate func playImageMarkCore(_ msg:String?,image:UIImage,completionHandler:HudHiddenCompletedHandler!){
        let vc = UIApplication.currentShowingViewController
        let vcView = vc.view ?? vc.navigationController?.view
        let hud = MBProgressHUD(view: vcView!)
        vcView!.addSubview(hud)
        
        hud.customView = UIImageView(image: image)
        hud.removeFromSuperViewOnHide = true
        // Set custom view mode
        hud.mode = MBProgressHUDMode.customView
        
        hud.delegate = vc
        hud.label.text = msg
        hud.isSquare = true
        if let handler = completionHandler
        {
            hudCompletionHandler[hud] = handler
        }
        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: 2)
        
    }
    
    func playImageMark(_ msg:String?,image:UIImage,async:Bool = true,completionHandler:HudHiddenCompletedHandler! = nil){
        if async
        {
            DispatchQueue.main.async { () -> Void in
                self.playImageMarkCore(msg, image: image, completionHandler: completionHandler)
            }
        }else
        {
            self.playImageMarkCore(msg, image: image, completionHandler: completionHandler)
        }
    }
    
    func showAlert(_ presentRootController:UIViewController,alertController:UIAlertController)
    {
        if #available(iOS 9.0, *) {
            alertController.preferredAction = alertController.actions.filter{$0.style == .default}.first
        }
        DispatchQueue.main.async(execute: { () -> Void in
            presentRootController.present(alertController, animated: true, completion: nil)
        })
    }
}
