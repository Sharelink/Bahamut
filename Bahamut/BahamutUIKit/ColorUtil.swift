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
    
    static let headerColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    static let footerColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    
    static var themeColor = UIColor(hexString: "#438ccb")
    static var navicationBarColor = UIColor(hexString: "#438ccb")
    static var navicationBarTintColor = UIColor.whiteColor()
}


extension UIColor
{
    
    static var headerColor:UIColor{
        return ColorSets.headerColor
    }
    static var footerColor:UIColor{
        return ColorSets.footerColor
    }
    
    static var themeColor:UIColor{
        return ColorSets.themeColor
    }
    
    static var navicationBarColor:UIColor{
        return ColorSets.navicationBarColor
    }
    
    static var navicationBarTintColor:UIColor{
        return ColorSets.navicationBarTintColor
    }
    
    static func getRondomColorIn(colors:[UIColor]) -> UIColor
    {
        let index = Int(arc4random_uniform(UInt32(colors.count)))
        return colors[index]
    }
    
    static func getRandomTextColor() -> UIColor
    {
        return getRondomColorIn(ColorSets.textColors)
    }
    
    static func getRandomColor() -> UIColor
    {
        return UIColor(hex: arc4random())
    }
}

