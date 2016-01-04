//
//  KeyboardAdjustHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
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
    
    var viewOriginHeight:CGFloat!
    
    private func adjustViewAdaptKeyboard(keyboardNotification:String,userInfo:[NSObject:AnyObject] ,responderView:UIView)
    {
        if viewOriginHeight == nil
        {
            viewOriginHeight = controller.view.frame.size.height
        }
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
                responderView.constraints.count
                for c in responderView.constraints
                {
                    if (c.firstItem as! NSObject == controller.view || c.secondItem as! NSObject == controller.view) && c.firstAttribute == .Bottom
                    {
                        c.constant = c.constant + offset
                    }
                }
                //controller.view.frame.size.height = viewOriginHeight - offset
                
                controller.view.layoutIfNeeded()
                UIView.commitAnimations()
            }else
            {
                if offset <= 0
                {
                    return
                }
                responderView.constraints.forEach({ (c) -> () in
                    if (c.firstItem as! NSObject == controller.view || c.secondItem as! NSObject == controller.view) && c.firstAttribute == .Bottom
                    {
                        c.constant = c.constant - offset
                    }
                })
                //controller.view.frame.size.height = viewOriginHeight
                controller.view.layoutIfNeeded()
            }
        }
    }
}