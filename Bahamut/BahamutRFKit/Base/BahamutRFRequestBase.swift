//
//  BahamutRFRequestBase.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

public class BahamutRFRequestBase : NSObject
{
    public static let maxRequestNoLimitCount:Int32 = 0
    static var requestCount = [String:Int32]()
    static let lock:NSRecursiveLock = NSRecursiveLock()
    
    public func getMaxRequestCount() -> Int32{
        return 1
    }
    
    public func incRequest()
    {
        
        let typeName = self.classForCoder.description()
        BahamutRFRequestBase.lock.lock()
        BahamutRFRequestBase.requestCount[typeName] = getCurrentRequestCount() + 1
        BahamutRFRequestBase.lock.unlock()
    }
    
    public func decRequest()
    {
        let typeName = self.classForCoder.description()
        BahamutRFRequestBase.lock.lock()
        BahamutRFRequestBase.requestCount[typeName] = getCurrentRequestCount() - 1
        BahamutRFRequestBase.lock.unlock()
    }
    
    public func isRequestLimited() -> Bool{
        let maxCount = getMaxRequestCount()
        let limited = maxCount != BahamutRFRequestBase.maxRequestNoLimitCount && getCurrentRequestCount() >= maxCount
        #if DEBUG
            if limited {
                let typeName = self.classForCoder.description()
                print("\(typeName) Is Limited")
            }
        #endif
        return limited
    }
    
    private func getCurrentRequestCount() -> Int32
    {
        let typeName = self.classForCoder.description()
        var result:Int32 = 0
        BahamutRFRequestBase.lock.lock()
        if let value = BahamutRFRequestBase.requestCount[typeName]
        {
            result = value
        }
        BahamutRFRequestBase.lock.unlock()
        return result
    }
    
    public var version:String!{
        didSet{
            if String.isNullOrWhiteSpace(version)
            {
                headers[version] = "1.0"
            }else
            {
                headers[version] = version
            }
        }
    }
    public var method:Alamofire.Method! = Method.GET
    public var apiServerUrl:String!
    public var api:String!
    public var encoding: ParameterEncoding = ParameterEncoding.URL
    internal(set) var paramenters:[String:String] = [String:String]()
    public var headers:[String:String] = [String:String]()
}
