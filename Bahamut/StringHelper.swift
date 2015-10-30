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

extension String {
    
    func toUTF8EncodingData() -> NSData!
    {
        return self.dataUsingEncoding(NSUTF8StringEncoding)
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

extension String{
    //分割字符
    func split(s:String)->[String]{
        if s.isEmpty{
            var x = [String]()
            for y in self.characters{
                x.append(String(y))
            }
            return x
        }
        return self.componentsSeparatedByString(s)
    }
    //去掉左右空格
    func trim()->String{
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    //是否包含字符串
    func has(s:String)->Bool{
        if (self.rangeOfString(s) != nil) {
            return true
        }else{
            return false
        }
    }
    //是否包含前缀
    func hasBegin(s:String)->Bool{
        if self.hasPrefix(s) {
            return true
        }else{
            return false
        }
    }
    //是否包含后缀
    func hasEnd(s:String)->Bool{
        if self.hasSuffix(s) {
            return true
        }else{
            return false
        }
    }
    
    func substringFromIndex(index:Int) -> String
    {
        return self.substringFromIndex(self.startIndex.advancedBy(index))
    }
    
    func substringToIndex(index:Int) -> String
    {
        return self.substringToIndex(self.startIndex.advancedBy(index))
    }
    
    func substringWithRange(startIndex:Index,endIndex:Index) -> String
    {
        return self.substringWithRange(Range<String.Index>(start: startIndex, end: endIndex))
    }
    
    func substringWithRange(startIndex:Int,endIndex:Int) -> String
    {
        return self.substringWithRange(Range<String.Index>(start: self.startIndex.advancedBy(startIndex), end: self.startIndex.advancedBy(endIndex)))
    }

    //反转
    func reverse()-> String{
        let s=self.split("").reverse()
        var x=""
        for y in s{
            x+=y
        }
        return x
    }
}

extension NSDate
{
    func toFriendlyString(formatter:NSDateFormatter! = nil) -> String
    {
        let interval = -self.timeIntervalSinceNow
        if interval < 60
        {
            return "new"
        }
        else if interval < 3600
        {
            return "\(Int(interval/60)) minutes ago"
        }else if interval < 3600 * 24
        {
            return "\(Int(interval/3600)) hours ago"
        }else if interval < 3600 * 24 * 7
        {
            return "\(Int(interval/3600/24)) days ago"
        }else if formatter == nil
        {
            return self.toLocalDateString()
        }else
        {
            return formatter.stringFromDate(self)
        }
    }
}

class ArrayUtil
{
    static func groupWithLatinLetter<T:AnyObject>(items:[T],orderBy:(T)->String) -> [(latinLetter:String,items:[T])]
    {
        var dict = [String:NSMutableArray]()
        for index in 0...25
        {
            let letterInt = 65 + index
            let key = StringHelper.IntToLetterString(letterInt)
            let list = NSMutableArray()
            dict.updateValue(list, forKey: key)
        }
        dict.updateValue(NSMutableArray(), forKey: "#")
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
            list?.addObject(item)
        }
        var result = dict.map {(latinLetter:$0.0, items:$0.1.map{$0 as! T}) }
        result.sortInPlace{$0.0 < $1.0}
        return result
    }
}
