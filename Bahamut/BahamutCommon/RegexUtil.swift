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
        if let matches = regex?.matchesInString(input,
            options: [],
            range: NSMakeRange(0, input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))) {
                return matches.count > 0
        } else {
            return false
        }
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
    return RegexMatcher(rhs).match(lhs)
}

