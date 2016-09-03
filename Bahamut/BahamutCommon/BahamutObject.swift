//
//  BahamutObject.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

//MARK:BahamutObject
public class BahamutObject : EVObject
{
    public func getObjectUniqueIdName() -> String
    {
        return "id"
    }
    
    public func getObjectUniqueIdValue() -> String
    {
        return valueForKey(getObjectUniqueIdName()) as! String
    }
    
    public func copyToObject<T:BahamutObject>(t:T.Type) -> T{
        return T(json:self.toJsonString())
    }
}

typealias BahamutObjectArray = Array<BahamutObject>

func debugLog(format: String, _ args: CVarArgType...) {
    #if DEBUG
        print("\(NSDate().toAccurateDateTimeString()): \(String(format: format, arguments: args))")
    #endif
}
