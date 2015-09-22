//
//  TestStringHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class StringHelper
{
    static func IntToLetter(letterIndex:Int) -> Character
    {
        return (Character(UnicodeScalar(letterIndex)))
    }
    
    static func IntToLetterString(letterIndex:Int) -> String
    {
        return "\(IntToLetter(letterIndex))"
    }
}

extension String
{
    static func isNullOrEmpty(value:String?) -> Bool
    {
        if let v = value
        {
            if v == ""
            {
                return true
            }
            return false
        }else
        {
            return true
        }
    }
    
    static func isNullOrWhiteSpace(value:String?) -> Bool
    {
        if isNullOrEmpty(value)
        {
            return true
        }else
        {
            let v = value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            return isNullOrEmpty(v)
        }
    }
}

extension NSDate
{
    func toFriendlyString() -> String
    {
        let interval = -self.timeIntervalSinceNow
        if interval < 60
        {
            return "new"
        }
        else if interval < 3600
        {
            return "\(Int(interval/60)) minutes ago"
        }else if self.timeIntervalSinceNow < 3600 * 24
        {
            return "\(Int(interval/3600)) hours ago"
        }else if self.timeIntervalSinceNow < 3600 * 24 * 7
        {
            return "\(Int(interval/3600/24)) days ago"
        }else
        {
            return self.toLocalDateString()
        }
    }
}

class ArrayUtil
{
    static func groupWithLatinLetter<T>(items:[T],orderBy:(T)->String) -> [(latinLetter:String,items:[T])]
    {
        var dict = [String:[T]]()
        for index in 0...25
        {
            let letterInt = 65 + index
            let key = StringHelper.IntToLetterString(letterInt)
            let list = [T]()
            dict.updateValue(list, forKey: key)
        }
        dict.updateValue([T](), forKey: "#")
        for item in items
        {
            let orderString = orderBy(item)
            let orderCFString:CFMutableStringRef = CFStringCreateMutableCopy(nil, 0, orderString);
            CFStringTransform(orderCFString,nil, kCFStringTransformToLatin, false)
            CFStringTransform(orderCFString, nil, kCFStringTransformStripDiacritics, false)
            
            let stringName = orderCFString as String
            let n = stringName.startIndex.advancedBy(1)
            let prefix = stringName.uppercaseString.substringToIndex(n)
            var list = dict[prefix]
            if list == nil
            {
                list = dict["#"]
            }
            list?.append(item)
            dict.updateValue(list!, forKey: prefix) //if not update ,the list in the dict is point to old list ,not appended list
        }
        var result = dict.map {(latinLetter:$0.0,items:$0.1)}
        result.sortInPlace{$0.0 < $1.0}
        return result
    }
}
