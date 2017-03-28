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

extension EVObject{
    
    static func fromJsonString<T:EVObject>(json:String?,_ t:T) -> T{
        let dict = EVReflection.dictionaryFromJson(json)
        return EVReflection.setPropertiesfromDictionary(dict, anyObject: t)
    }
    
    static func fromDictionary<T:EVObject>(dict:NSDictionary,_ t:T) -> T{
        return EVReflection.setPropertiesfromDictionary(dict, anyObject: t)
    }
    
    func toJsonString() -> String {
        return toJsonString(ConversionOptions.DefaultSerialize, prettyPrinted: false)
    }
}

open class BahamutObject : EVObject
{
    open func getObjectUniqueIdName() -> String
    {
        return "id"
    }
    
    open func getObjectUniqueIdValue() -> String
    {
        return value(forKey: getObjectUniqueIdName()) as! String
    }
    
    open func copyToObject<T:BahamutObject>(_ t:T.Type) -> T where T:BahamutObject{
        return EVReflection.setPropertiesfromDictionary(self.toDictionary(), anyObject: T())
    }
}

typealias BahamutObjectArray = Array<BahamutObject>
