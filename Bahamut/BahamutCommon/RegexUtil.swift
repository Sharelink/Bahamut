//
//  RegexHelper.swift
//  Sharelink
//
//  Created by AlexChow on 15/8/14.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



public struct RegexMatcher {
    let regex: NSRegularExpression?
    
    init(_ pattern: String) {
        do
        {
            try regex = NSRegularExpression(pattern: pattern,
                options: .caseInsensitive)
        }catch let error as NSError
        {
            regex = nil
            debugLog(error.description)
        }
    }
    
    func match(_ input: String) -> Bool {
        let range = NSMakeRange(0, input.lengthOfBytes(using: String.Encoding.utf8))
        let matches = regex?.matches(in: input, options: [],range: range)
        return matches?.count > 0
    }
    
    func matchFirstString(_ input:String) -> String?{
        if let matches = regex?.firstMatch(in: input,
            options: [],
            range: NSMakeRange(0, input.lengthOfBytes(using: String.Encoding.utf8))) {
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

/*
infix operator.isRegexMatch(pattern:{
associativity none
precedence 130
}
*/

extension String{
    func isRegexMatch(pattern:String) -> Bool {
        if let _ = self.range(of: pattern, options: .regularExpression) {
            return true
        }
        return false
    }
}

//MARK: String Util
extension String{
    func isMobileNumber() -> Bool{
        return self.isRegexMatch(pattern:"^((13[0-9])|(15[^4,\\D])|(18[0-9]))\\d{8}$")
    }
    
    func isEmail() -> Bool{
        return self.isRegexMatch(pattern:"^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$")
    }
    
    func isPassword() -> Bool{
        return self.isRegexMatch(pattern:"^[\\@A-Za-z0-9\\!\\#\\$\\%\\^\\&\\*\\.\\~]{6,22}$")
    }
    
    func isUsername() -> Bool{
        return self.isRegexMatch(pattern:"^[_a-zA-Z0-9\\u4e00-\\u9fa5]{2,23}$")
    }
}

