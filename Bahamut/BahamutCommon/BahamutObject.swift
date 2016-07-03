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
}

typealias BahamutObjectArray = Array<BahamutObject>
