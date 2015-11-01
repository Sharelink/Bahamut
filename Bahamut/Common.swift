//
//  Common.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/16.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
struct ColorSets
{
    static let textColors:[UIColor] =
    [
        UIColor.redColor(),
        UIColor.orangeColor(),
        UIColor.greenColor(),
        UIColor.cyanColor(),
        UIColor.blueColor(),
        UIColor.purpleColor(),
        UIColor.blackColor(),
        themeColor
    ]
    
    static let themeColor = UIColor(hexString: "#438ccb")
}


extension UIColor
{
    
    static var themeColor:UIColor{
        return ColorSets.themeColor
    }
    
    static func getRandomTextColor() -> UIColor
    {
        let index = Int(arc4random_uniform(UInt32(ColorSets.textColors.count)))
        return ColorSets.textColors[index]
    }
    
    static func getRandomColor() -> UIColor
    {
        return UIColor(hex: arc4random())
    }
}
