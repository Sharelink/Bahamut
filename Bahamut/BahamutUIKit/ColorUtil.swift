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
        UIColor.red,
        UIColor.orange,
        UIColor.green,
        UIColor.cyan,
        UIColor.blue,
        UIColor.purple,
        UIColor.black,
        themeColor
    ]
    
    static let headerColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    static let footerColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    
    static var themeColor = UIColor(hexString: "#438ccb")
    static var navBarBcgColor = UIColor(hexString: "#438ccb")
    static var navBarTintColor = UIColor.white
    static var navBarTitleColor = UIColor.white
}

extension UIColor{
    var hexValue:Int{
        return Int(toHex())
    }
    
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
    
    static var navBarBcgColor:UIColor{
        return ColorSets.navBarBcgColor
    }
    
    static var navBarTintColor:UIColor{
        return ColorSets.navBarTintColor
    }
    
    static var navBarTitleColor:UIColor{
        return ColorSets.navBarTitleColor
    }
    
    static func getRondomColorIn(_ colors:[UIColor]) -> UIColor
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


extension UIColor{
    static var sky:UIColor{
        return UIColor(hexString: "#66CCFF")
    }
    
    static var ice:UIColor{
        return UIColor(hexString: "#66FFFF")
    }
    
    static var turquoise:UIColor{
        return UIColor(hexString: "#00FFFF")
    }
    
    static var seaFoam:UIColor{
        return UIColor(hexString: "#00FF80")
    }
    
    static var lime:UIColor{
        return UIColor(hexString: "#80FF00")
    }
    
    static var banana:UIColor{
        return UIColor(hexString: "#FFFF66")
    }
}
