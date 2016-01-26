//
//  TestStringHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CommonCrypto

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
        return self.substringWithRange(Range<String.Index>(start: startIndex, end: endIndex))
    }
    
    public func substringWithRange(startIndex:Int,endIndex:Int) -> String
    {
        return self.substringWithRange(Range<String.Index>(start: self.startIndex.advancedBy(startIndex), end: self.startIndex.advancedBy(endIndex)))
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

