//
//  MainViewTabBarController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import MBProgressHUD

extension UIViewController
{
    func makeRootViewToast(msg:String)
    {
        if let vc = MainViewTabBarController.currentRootViewController
        {
            vc.view.makeToast(message: msg)
        }
    }
    
    func makeRootViewHUDToadt(msg:String)
    {
        if let vc = MainViewTabBarController.currentRootViewController
        {
            vc.view.makeToast(message: msg)
        }
    }
}

class MainViewTabBarController: UITabBarController ,OrientationsNavigationController
{
    private(set) static var currentTabBarViewController:MainViewTabBarController!
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        MainViewTabBarController.currentTabBarViewController = self
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        MainViewTabBarController.currentTabBarViewController = nil
    }
}
