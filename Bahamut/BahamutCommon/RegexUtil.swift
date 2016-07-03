//
//  RegexHelper.swift
//  Sharelink
//
//  Created by AlexChow on 15/8/14.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


public struct RegexMatcher {
    let regex: NSRegularExpression?
    
    init(_ pattern: String) {
        do
        {
            try regex = NSRegularExpression(pattern: pattern,
                options: .CaseInsensitive)
        }catch let error as NSError
        {
            regex = nil
            NSLog(error.description)
        }
    }
    
    func match(input: String) -> Bool {
        let range = NSMakeRange(0, input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let matches = regex?.matchesInString(input, options: [],range: range)
        return matches?.count > 0
    }
    
    func matchFirstString(input:String) -> String?{
        if let matches = regex?.firstMatchInString(input,
            options: [],
            range: NSMakeRange(0, input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))) {
                if let range = matches.range.toRange()
                {
                    return input.substringWithRange(range)
                }else
                {
                    return nil
                }
        } else {
            return nil
        }
    }
}

infix operator =~ {
associativity none
precedence 130
}

public func =~(lhs: String, rhs: String) -> Bool {
    
    if let _ = lhs.rangeOfString(rhs, options: .RegularExpressionSearch) {
        return true
    }
    return false
}

//MARK: String Util
extension String{
    func isMobileNumber() -> Bool{
        return self =~ "^((13[0-9])|(15[^4,\\D])|(18[0-9]))\\d{8}$"
    }
    
    func isEmail() -> Bool{
        return self =~ "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$"
    }
    
    func isPassword() -> Bool{
        return self =~ "^[\\@A-Za-z0-9\\!\\#\\$\\%\\^\\&\\*\\.\\~]{6,22}$"
    }
    
    func isUsername() -> Bool{
        return self =~ "^[_a-zA-Z0-9\\u4e00-\\u9fa5]{2,23}$"
    }
}

