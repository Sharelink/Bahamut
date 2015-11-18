//
//  MainViewTabBarController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

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
            hud.hide(true)
        }
    }
    
    public func hudWasHidden(hud: MBProgressHUD!) {
        hud.removeFromSuperview()
    }
    
    func makeToastActivity()
    {
        self.makeToastActivityWithMessage("", message: "")
    }
    
    func makeToastActivityWithMessage(title:String!,message:String!)
    {
        let HUD = MBProgressHUD(view: self.navigationController!.view)
        self.navigationController!.view.addSubview(HUD)
        
        HUD.delegate = self
        HUD.labelText = title
        HUD.detailsLabelText = message
        HUD.square = true
        HUD.show(true)
        toastActivityMap[self] = HUD
    }
    
    func showToast(msg:String)
    {
        let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        // Configure for text only and offset down
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = msg
        hud.margin = 10;
        hud.delegate = self
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 1)
    }
    
    func showCheckMark(msg:String)
    {
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
    
    func showAlert(title:String!,msg:String!,actions:[UIAlertAction] = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style:.Cancel, handler: nil)])
    {
        let controller = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        for ac in actions
        {
            controller.addAction(ac)
        }
        showAlert(controller)
    }
    
    func showAlert(alertController:UIAlertController) -> Bool
    {
        if let vc = MainViewTabBarController.currentRootViewController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.presentViewController(alertController, animated: true, completion: nil)
            })
            return true
        }else if let vc = MainViewTabBarController.currentNavicationController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.presentViewController(alertController, animated: true, completion: nil)
            })
            return true
        }
        return false
    }
}

class MainViewTabBarController: UITabBarController ,OrientationsNavigationController
{
    private(set) static var currentTabBarViewController:MainViewTabBarController!
    
    static var currentNavicationController:UINavigationController!{
        if let mc = currentTabBarViewController.selectedViewController as? UINavigationController
        {
            return mc
        }
        return nil
    }
    
    static var currentRootViewController:UIViewController!{
        if let mc = currentTabBarViewController.selectedViewController?.presentingViewController as? MainNavigationController
        {
            return mc.presentedViewController
        }
        return nil
    }
    
    func supportedViewOrientations() -> UIInterfaceOrientationMask
    {
        if let pvc = self.selectedViewController as? OrientationsNavigationController
        {
            return pvc.supportedViewOrientations()
        }
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MainViewTabBarController.currentTabBarViewController = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        MainViewTabBarController.currentTabBarViewController = nil
    }
}
