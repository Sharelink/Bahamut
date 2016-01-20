//
//  UIAnimationHelper.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

extension UIView
{
    func shakeAnimationForView(repeatTimes:Float = 3,completion:AnimationCompletedHandler! = nil)
    {
        UIAnimationHelper.shakeAnimationForView(self,repeatTimes:repeatTimes,completion: completion)
    }
    
    func animationMaxToMin(completion:AnimationCompletedHandler! = nil)
    {
        UIAnimationHelper.animationMaxToMin(self,completion: completion)
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
        animation.delegate = view
        if let handler = completion
        {
            UIAnimationHelper.instance.animationCompleted[view] = handler
        }
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
        animation.delegate = view
        if let handler = completion
        {
            UIAnimationHelper.instance.animationCompleted[view] = handler
        }
        // 设置运动形式
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        // 设置开始位置
        animation.fromValue = NSValue(CGPoint: a)
        
        // 设置结束位置
        animation.toValue = NSValue(CGPoint: b)
        
        // 设置时间
        animation.duration = 1
        
        // 添加上动画
        viewLayer.addAnimation(animation, forKey: nil)
    }
    
    static func animationMaxToMin(view:UIView,completion:AnimationCompletedHandler! = nil){
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.delegate = view
        if let handler = completion
        {
            UIAnimationHelper.instance.animationCompleted[view] = handler
        }
        animation.fromValue = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.toValue = 1.1
        animation.duration = 0.2
        animation.repeatCount = 0
        animation.autoreverses = true
        animation.removedOnCompletion = true
        animation.fillMode = kCAFillModeForwards;
        view.layer.addAnimation(animation, forKey: "Float")
    }
}
