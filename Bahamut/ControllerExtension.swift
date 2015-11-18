//
//  TapViewBgHideKeyBoardExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

public class NoStatusBarViewController :UIViewController
{
    public override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

public class UserGuide:NSObject
{
    private var viewController:UIViewController!
    private var guideImages:[UIImage]!
    private var userId:String!
    private var showingIndex:Int = 0
    private var imgController:NoStatusBarViewController!
    private var imageView:UIImageView!
    private var isInited:Bool = false
    public func initGuide<T:UIViewController>(controller:T,userId:String,guideImgs:[UIImage])
    {
        viewController = controller
        guideImages = guideImgs
        self.userId = userId
        initImageViewController()
        isInited = true
        
        let className = T.description()
        firstTimeStoreKey = "showGuideMark:\(self.userId)\(className)"
    }
    
    private var firstTimeStoreKey:String!
    
    private func initImageViewController()
    {
        imgController = NoStatusBarViewController()
        imgController.view.frame = (UIApplication.sharedApplication().keyWindow?.bounds)!
        imageView = UIImageView(frame: imgController.view.bounds)
        imgController.view.addSubview(imageView)
        self.imgController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onTapImage:"))
    }
    
    public func deInitUserGuide()
    {
        isInited = false
        self.viewController = nil
        self.imageView = nil
        self.imgController = nil
        self.guideImages = nil
        self.firstTimeStoreKey = nil
    }
    
    public func onTapImage(_:UITapGestureRecognizer)
    {
        showNextImage()
    }
    
    private func showNextImage()
    {
        self.showingIndex++
        if showingIndex >= self.guideImages.count
        {
            self.viewController.dismissViewControllerAnimated(false, completion: {
                self.deInitUserGuide()
            })
        }else
        {
            self.imageView.image = self.guideImages[self.showingIndex]
        }
    }
    
    public func showGuide()
    {
        if isInited && self.guideImages != nil && self.guideImages.count > 0
        {
            self.showingIndex = -1
            self.viewController.presentViewController(imgController, animated: true, completion: {
                self.showNextImage()
            })
        }
    }
    
    public func showGuideControllerPresentFirstTime()
    {
        if isInited && self.guideImages != nil && self.guideImages.count > 0
        {
            let key = firstTimeStoreKey
            let showed = NSUserDefaults.standardUserDefaults().boolForKey(key)
            if !showed
            {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
                showGuide()
            }else
            {
                deInitUserGuide()
            }
        }
    }
}

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

extension UIViewController
{
    func changeNavigationBarColor()
    {
        let navBcgColor = UIColor.themeColor
        self.navigationController?.navigationBar.barTintColor = navBcgColor
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        if let nav = self as? UINavigationController
        {
            nav.navigationBar.barTintColor = navBcgColor
            nav.navigationBar.tintColor = UIColor.whiteColor()
        }
    }
}

@objc
protocol OrientationsNavigationController
{
    func supportedViewOrientations() -> UIInterfaceOrientationMask
}

class UIOrientationsNavigationController: UINavigationController ,OrientationsNavigationController
{
    var lockOrientationPortrait:Bool = false
    func supportedViewOrientations() -> UIInterfaceOrientationMask {
        if lockOrientationPortrait
        {
            return UIInterfaceOrientationMask.Portrait
        }
        return UIInterfaceOrientationMask.All
    }
}