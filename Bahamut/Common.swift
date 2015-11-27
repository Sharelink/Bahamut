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
    
    static let themeColor = UIColor(hexString: "#438ccb")
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

class IdUtil
{
    static func generateUniqueId() -> String
    {
        let code = "\(NSDate().toAccurateDateTimeString())_\(random())"
        return code.md5
    }
}

extension String {
    var md5 : String{
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen);
        
        CC_MD5(str!, strLen, result);
        
        let hash = NSMutableString();
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i]);
        }
        result.destroy();
        
        return String(format: hash as String)
    }
    
    var sha256 : String{
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen);
        
        CC_SHA256(str!, strLen, result)
        
        let hash = NSMutableString();
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i]);
        }
        result.destroy();
        
        return String(format: hash as String)
    }
}
