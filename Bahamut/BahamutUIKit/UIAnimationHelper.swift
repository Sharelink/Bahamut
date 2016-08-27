//
//  UIAnimationHelper.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import QuartzCore

extension UIView
{
    func startFlash(duration:NSTimeInterval = 0.8) {
        UIAnimationHelper.flashView(self, duration: duration)
    }
    
    func stopFlash() {
        UIAnimationHelper.stopFlashView(self)
    }
    
    func shakeAnimationForView(repeatTimes:Float = 3,completion:AnimationCompletedHandler! = nil)
    {
        UIAnimationHelper.shakeAnimationForView(self,repeatTimes:repeatTimes,completion: completion)
    }
    
    func animationMaxToMin(duration:Double = 0.2,maxScale:CGFloat = 1.1,completion:AnimationCompletedHandler! = nil)
    {
        UIAnimationHelper.animationMaxToMin(self,duration:duration,maxScale: maxScale,completion: completion)
    }
    
    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let handler = UIAnimationHelper.instance.animationCompleted.removeValueForKey(self)
        {
            handler()
        }
    }
}

typealias AnimationCompletedHandler = ()->Void

class UIAnimationHelper {
    
    private var animationCompleted = [UIView:AnimationCompletedHandler]()
    private static let instance = UIAnimationHelper()

    static func animationPageCurlView(view:UIView,duration:NSTimeInterval,completion:AnimationCompletedHandler! = nil){
        
        // 获取到当前的View
        
        let viewLayer = view.layer
        
        
        // 设置动画
        
        let animation = CATransition()
        
        animation.duration = duration
        
        animation.type = "pageCurl"
        
        animation.subtype = kCATransitionFromBottom
        
        
        // 添加上动画
        viewLayer.addAnimation(animation, forKey: nil)
        
        playAnimation(view, animation: animation, key: "animationPageCurl", completion: completion)
    }

    
    static func shakeAnimationForView(view:UIView,repeatTimes:Float,completion:AnimationCompletedHandler! = nil){
        
        // 获取到当前的View
        
        let viewLayer = view.layer
        
        // 获取当前View的位置
        
        let position:CGPoint = viewLayer.position
        
        // 移动的两个终点位置
        
        let a = CGPointMake(position.x + 10, position.y)
        
        let b = CGPointMake(position.x - 10, position.y)
        
        // 设置动画
        
        let animation = CABasicAnimation(keyPath: "position")
        // 设置运动形式
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        // 设置开始位置
        animation.fromValue = NSValue(CGPoint: a)
        
        // 设置结束位置
        animation.toValue = NSValue(CGPoint: b)
        
        // 设置自动反转
        animation.autoreverses = true
        
        // 设置时间
        animation.duration = 0.05
        
        // 设置次数
        animation.repeatCount = repeatTimes
        
        // 添加上动画
        viewLayer.addAnimation(animation, forKey: nil)
        
        playAnimation(view, animation: animation, key: "shakeAnimationForView", completion: completion)
    }
    
    static func flyToTopForView(startPosition:CGPoint,view:UIView,completion:AnimationCompletedHandler! = nil){
        
        // 获取到当前的View
        
        let viewLayer = view.layer
        
        // 获取当前View的位置
        
        let position:CGPoint = viewLayer.position
        
        // 移动的两个终点位置
        
        let a = startPosition
        
        let b = CGPointMake(position.x, -10)
        
        // 设置动画
        
        let animation = CABasicAnimation(keyPath: "position")
        // 设置运动形式
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        // 设置开始位置
        animation.fromValue = NSValue(CGPoint: a)
        
        // 设置结束位置
        animation.toValue = NSValue(CGPoint: b)
        
        // 设置时间
        animation.duration = 1
        
        playAnimation(view, animation: animation, key: "flyToTopForView", completion: completion)
    }
    
    static func animationMaxToMin(view:UIView,duration:Double,maxScale:CGFloat,completion:AnimationCompletedHandler! = nil){
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.toValue = maxScale
        animation.duration = duration
        animation.repeatCount = 0
        animation.autoreverses = true
        animation.removedOnCompletion = true
        animation.fillMode = kCAFillModeForwards;
        playAnimation(view, animation: animation, key: "animationMaxToMin", completion: completion)
    }
    
    static func playAnimation(view:UIView,animation:CAAnimation,key:String? = nil,completion:AnimationCompletedHandler! = nil)
    {
        animation.delegate = view
        if let handler = completion
        {
            UIAnimationHelper.instance.animationCompleted[view] = handler
        }
        view.layer.addAnimation(animation, forKey: key)
    }
    
    static func flashView(view:UIView,duration:NSTimeInterval = 0.8,autoStop:Bool = false,stopAfterMs:UInt64 = 3000,completion:AnimationCompletedHandler! = nil) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.autoreverses = true
        animation.duration = duration
        animation.repeatCount = MAXFLOAT
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.timingFunction=CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        view.layer.addAnimation(animation, forKey: "Flash")
        if autoStop{
            let time = dispatch_time(DISPATCH_TIME_NOW, NSNumber(unsignedLongLong: NSEC_PER_MSEC * stopAfterMs).longLongValue)
            dispatch_after(time, dispatch_get_main_queue(), {
                stopFlashView(view)
                completion?()
            })
        }
    }
    
    static func stopFlashView(view:UIView) {
        view.layer.removeAnimationForKey("Flash")
    }
}

func dispatch_after(ms:UInt64,queue:dispatch_queue_t,handler:()->Void) {
    let time = dispatch_time(DISPATCH_TIME_NOW, NSNumber(unsignedLongLong: NSEC_PER_MSEC * ms).longLongValue)
    dispatch_after(time, queue,handler)
}

func dispatch_main_queue_after(ms:UInt64,handler:()->Void) {
    dispatch_after(ms, queue: dispatch_get_main_queue(), handler: handler)
}
