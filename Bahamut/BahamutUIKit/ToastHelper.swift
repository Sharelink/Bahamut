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

let ALERT_ACTION_OK = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style:.Cancel, handler: nil)]
let ALERT_ACTION_I_SEE = [UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style:.Cancel, handler: nil)]
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
        self.makeToastActivityWithMessage("", message: "")
    }
    
    func makeToastActivityWithMessage(title:String!,message:String!)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let HUD = MBProgressHUD(view: self.navigationController!.view)
            self.navigationController!.view.addSubview(HUD)
            
            HUD.delegate = self
            HUD.labelText = title
            HUD.detailsLabelText = message
            HUD.square = true
            HUD.show(true)
            toastActivityMap[self] = HUD
        })
        
    }
    
    func showToast(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
            // Configure for text only and offset down
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = msg
            hud.margin = 10;
            hud.delegate = self
            hud.removeFromSuperViewOnHide = true
            hud.hide(true, afterDelay: 1)
        }
        
    }
    
    func showCheckMark(msg:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let HUD = MBProgressHUD(view: self.navigationController!.view)
            self.navigationController?.view.addSubview(HUD)
            
            HUD.customView = UIImageView(image: UIImage(named: "Checkmark"))
            
            // Set custom view mode
            HUD.mode = MBProgressHUDMode.CustomView
            
            HUD.delegate = self
            HUD.labelText = msg
            HUD.square = true
            HUD.show(true)
            HUD.hide(true, afterDelay: 1)
        }
    }
    
    func showAlert(title:String!,msg:String!,actions:[UIAlertAction] = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style:.Cancel, handler: nil)])
    {
        let controller = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        for ac in actions
        {
            controller.addAction(ac)
        }
        showAlert(controller)
    }
    
    func showAlert(presentRootController:UIViewController,alertController:UIAlertController)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            presentRootController.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}