//
//  TestStringHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

public class StringHelper
{
    public static func IntToLetter(letterIndex:Int) -> Character
    {
        return (Character(UnicodeScalar(letterIndex)))
    }
    
    public static func IntToLetterString(letterIndex:Int) -> String
    {
        return "\(IntToLetter(letterIndex))"
    }
}

public extension String {
    
    public func toUTF8EncodingData() -> NSData!
    {
        return self.dataUsingEncoding(NSUTF8StringEncoding)
    }
}
public extension String
{
    
    public static func isNullOrEmpty(value:String?) -> Bool
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
    
    public static func isNullOrWhiteSpace(value:String?) -> Bool
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

public extension String{
    public static func jsonStringWithDictionary(dict:NSDictionary) -> String?{
        do{
            let j = try NSJSONSerialization.dataWithJSONObject(dict, options: .PrettyPrinted)
            return String(data: j, encoding: NSUTF8StringEncoding)
        }catch{
            return nil
        }
    }
    
    public static func miniJsonStringWithDictionary(dict:NSDictionary) -> String?{
        do{
            let j = try NSJSONSerialization.dataWithJSONObject(dict,options: NSJSONWritingOptions(rawValue: UInt(0)))
            return String(data: j, encoding: NSUTF8StringEncoding)
        }catch{
            return nil
        }
    }
}

public extension String{
    //分割字符
    public func split(s:String)->[String]{
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
    public func trim()->String{
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    //是否包含字符串
    public func has(s:String)->Bool{
        if (self.rangeOfString(s) != nil) {
            return true
        }else{
            return false
        }
    }
    //是否包含前缀
    public func hasBegin(s:String)->Bool{
        if self.hasPrefix(s) {
            return true
        }else{
            return false
        }
    }
    //是否包含后缀
    public func hasEnd(s:String)->Bool{
        if self.hasSuffix(s) {
            return true
        }else{
            return false
        }
    }
    
    public func substringFromIndex(index:Int) -> String
    {
        return self.substringFromIndex(self.startIndex.advancedBy(index))
    }
    
    public func substringToIndex(index:Int) -> String
    {
        return self.substringToIndex(self.startIndex.advancedBy(index))
    }
    
    public func substringWithRange(startIndex:Index,endIndex:Index) -> String
    {
        return self.substringWithRange(startIndex..<endIndex)
    }
    
    public func substringWithRange(startIndex:Int,endIndex:Int) -> String
    {
        return self.substringWithRange(self.startIndex.advancedBy(startIndex)..<self.startIndex.advancedBy(endIndex))
    }
    
    public func substringWithRange(range:Range<Int>) -> String
    {
        if let start = range.first
        {
            if let end = range.last
            {
                return substringWithRange(start, endIndex: end + 1)
            }
        }
        return ""
    }

    //反转
    public func reverse()-> String{
        let s=self.split("").reverse()
        var x=""
        for y in s{
            x+=y
        }
        return x
    }
}

func LocalizedString(key:String,tableName:String? = nil, bundle:NSBundle! = NSBundle.mainBundle()) -> String
{
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: "", comment: "")
}

