//
//  TapViewBgHideKeyBoardExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

//MARK: Keyboard
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

public class ControllerViewAdjustByKeyboardProxy : NSObject
{
    private var controller:UIViewController!
    
    init(controller:UIViewController)
    {
        self.controller = controller
    }
    
    public func removeObserverForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func registerForKeyboardNotifications(views:[UIView])
    {
        keyBoardAdjuetResponderViews = views
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChanged:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChanged:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private var keyBoardAdjuetResponderViews = [UIView]()
    
    private var offset:CGFloat = 0
    func keyboardChanged(aNotification:NSNotification)
    {
        if let userInfo = aNotification.userInfo
        {
            if let responderView = (keyBoardAdjuetResponderViews.filter{$0.isFirstResponder()}.first)
            {
                self.adjustViewAdaptKeyboard(aNotification.name, userInfo: userInfo, responderView: responderView)
            }
        }
        
    }
    
    private func adjustViewAdaptKeyboard(keyboardNotification:String,userInfo:[NSObject:AnyObject] ,responderView:UIView)
    {
        let info = userInfo
        if !responderView.isFirstResponder()
        {
            return
        }
        if let kbFrame = info[UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        {
            let tfFrame = responderView.frame
            
            if keyboardNotification == UIKeyboardDidShowNotification
            {
                offset = tfFrame.origin.y + tfFrame.size.height + 7 - kbFrame.origin.y
                if offset <= 0
                {
                    return
                }
                var animationDuration:NSTimeInterval
                var animationCurve:UIViewAnimationCurve
                let curve = info[UIKeyboardAnimationCurveUserInfoKey] as! Int
                animationCurve = UIViewAnimationCurve(rawValue: curve)!
                animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
                UIView.beginAnimations(nil, context:nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(animationCurve)
                
                controller.view.frame.origin.y = -offset
                
                controller.view.layoutIfNeeded()
                UIView.commitAnimations()
            }else
            {
                if offset <= 0
                {
                    return
                }
                controller.view.frame.origin.y = 0
                controller.view.layoutIfNeeded()
            }
        }
    }
}

//MARK: ScreenLock
//TODO: complete this
class ScreenLockProxy:NSObject
{
    var lockScreenLayer = UIView(){
        didSet{
            let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            lockScreenLayer.frame = (appDel.window?.frame)!
            lockScreenLayer.backgroundColor = UIColor.clearColor()
        }
    }
    
    static let sharedInstance:ScreenLockProxy = {
        return ScreenLockProxy()
    }()
    
    func lockScreen(controller:UIViewController)
    {
        //controller.view.addSubview(self.lockScreenLayer)
    }
    
    func unlockScreen(controller:UIViewController)
    {
        //self.lockScreenLayer.removeFromSuperview()
        
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
        ScreenLockProxy.sharedInstance.lockScreen(self)
    }
    
    func unlockScreen()
    {
        ScreenLockProxy.sharedInstance.unlockScreen(self)
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