//
//  ArrayUril.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/11/1.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


public extension Array
{
    public mutating func removeElement(predict:(itemInArray:Element) -> Bool) ->[Element]
    {
        var result = [Element]()
        let start = self.count - 1
        for i in start...0
        {
            let a = self[i]
            if predict(itemInArray: a)
            {
                let item = self.removeAtIndex(i)
                result.append(item)
            }
        }
        return result
    }
    
    public func toMap<T:NSObject>(m:(elem:Element)-> T) -> [T:Element]
    {
        var result = [T:Element]()
        for e in self{
            let key = m(elem: e)
            result[key] = e
        }
        return result
    }
    
    public func messArrayUp() -> [Element]
    {
        var result = self.map{$0}
        for _ in 0..<3
        {
            for _ in 0..<self.count
            {
                let index = Int(arc4random_uniform(UInt32(self.count)))
                let indexb = Int(arc4random_uniform(UInt32(self.count)))
                let a = result[index]
                result[index] = result[indexb]
                result[indexb] = a
            }
        }
        return result
    }
    
    public func getRandomSubArray(subArrayCount:Int) -> [Element]
    {
        var result = [Element]()
        let messArray = self.messArrayUp()
        for i in 0..<min(messArray.count , subArrayCount)
        {
            result.append(messArray[i])
        }
        return result.messArrayUp()
    }
    
}

public extension Array
{
    public func forIndexEach(body:(i:Int,element:Element)->Void)
    {
        var i = 0
        self.forEach { (element) -> () in
            body(i: i + 1, element: element)
            i += 1
        }
    }
}

public extension Array
{
    public mutating func swapElement(aIndex:Int,bIndex:Int) -> Bool
    {
        if self.count > aIndex && self.count > bIndex
        {
            let tmp = self[aIndex]
            self[aIndex] = self[bIndex]
            self[bIndex] = tmp
            return true
        }
        return false
    }
}

public class ArrayUtil
{
    public static func groupWithLatinLetter<T:AnyObject>(items:[T],orderBy:(T)->String) -> [(latinLetter:String,items:[T])]
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
