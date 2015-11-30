//
//  ShareLinkObject.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

public class ShareLinkObject : EVObject
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