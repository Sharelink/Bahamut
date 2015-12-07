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
    func shakeAnimationForView(repeatTimes:Float = 3)
    {
        UIAnimationHelper.shakeAnimationForView(self,repeatTimes:repeatTimes)
    }
}

class UIAnimationHelper: UIViewController {
    static func shakeAnimationForView(view:UIView,repeatTimes:Float){
        
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
    }
    
    static func flyToTopForView(startPosition:CGPoint,view:UIView){
        
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
        
        // 添加上动画
        viewLayer.addAnimation(animation, forKey: nil)
    }
}
