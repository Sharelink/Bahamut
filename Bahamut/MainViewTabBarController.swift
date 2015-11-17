//
//  MainViewTabBarController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

let ALERT_ACTION_OK = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style:.Cancel, handler: nil)]
let ALERT_ACTION_I_SEE = [UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style:.Cancel, handler: nil)]

extension UIViewController
{
    func makeRootViewToast(msg:String)
    {
        if let vc = MainViewTabBarController.currentRootViewController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.view.makeToast(message: msg)
            })
        }
    }
    
    func makeRootViewHUDToast(msg:String)
    {
        if let vc = MainViewTabBarController.currentRootViewController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.view.makeToast(message: msg)
            })
        }else if let vc = MainViewTabBarController.currentNavicationController
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                vc.view.makeToast(message: msg)
            })
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
