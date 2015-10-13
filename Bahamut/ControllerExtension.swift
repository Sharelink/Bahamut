//
//  TapViewBgHideKeyBoardExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

extension UIViewController
{
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        hideKeyBoard()
    }
    
    func hideKeyBoard()
    {
        self.view.endEditing(true)
    }
}

//TODO: complete this
class ScreenLockProxy:NSObject
{
    var lockScreenLayer = UIView(){
        didSet{
            
        }
    }
    
    static let sharedInstance:ScreenLockProxy = {
        return ScreenLockProxy()
    }()
    
    func lockScreen()
    {
    }
    
    func unlockScreen()
    {
        
    }
    
}

extension UIViewController
{
    func changeNavigationBarColor()
    {
        let navBcgColor = UIColor.themeColor
        self.navigationController?.navigationBar.tintColor = navBcgColor
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
}

extension UIViewController
{
    func lockScreen()
    {
        ScreenLockProxy.sharedInstance.lockScreen()
    }
    
    func unlockScreen()
    {
        ScreenLockProxy.sharedInstance.unlockScreen()
    }
}

@objc
protocol OrientationsNavigationController
{
    func supportedViewOrientations() -> UIInterfaceOrientationMask
}

class UIOrientationsNavigationController: UINavigationController ,OrientationsNavigationController
{
    func supportedViewOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
}