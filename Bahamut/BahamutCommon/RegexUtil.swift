//
//  RegexHelper.swift
//  Sharelink
//
//  Created by AlexChow on 15/8/14.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


public struct RegexUtil {
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
}

infix operator =~ {
associativity none
precedence 130
}

public func =~(lhs: String, rhs: String) -> Bool {
    return RegexUtil(rhs).match(lhs)
}

