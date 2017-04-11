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

open class BahamutRFRequestBase : NSObject
{
    open static let maxRequestNoLimitCount:Int32 = 0
    static var requestCount = [String:Int32]()
    static let lock:NSRecursiveLock = NSRecursiveLock()
    
    private(set) var requestStartTs:Int64!
    private(set) var requestEndTs:Int64!
    
    var requestTs:Int64{
        return (requestEndTs ?? 0) - (requestStartTs ?? 0)
    }
    
    open var method:HTTPMethod = .get
    open var apiServerUrl:String!
    open var api:String!
    open var encoding = URLEncoding.default
    internal(set) var paramenters:[String:String] = [String:String]()
    open var headers:[String:String] = [String:String]()
    
    open func getMaxRequestCount() -> Int32{
        return 1
    }
    
    open func incRequest()
    {
        requestStartTs = DateHelper.UnixTimeSpanTotalMilliseconds
        let typeName = "\(type(of: self))"
        BahamutRFRequestBase.lock.lock()
        BahamutRFRequestBase.requestCount[typeName] = getCurrentRequestCount() + 1
        BahamutRFRequestBase.lock.unlock()
    }
    
    open func decRequest()
    {
        let typeName = "\(type(of: self))"
        BahamutRFRequestBase.lock.lock()
        BahamutRFRequestBase.requestCount[typeName] = getCurrentRequestCount() - 1
        BahamutRFRequestBase.lock.unlock()
        requestEndTs = DateHelper.UnixTimeSpanTotalMilliseconds
    }
    
    open func isRequestLimited() -> Bool{
        let maxCount = getMaxRequestCount()
        let limited = maxCount != BahamutRFRequestBase.maxRequestNoLimitCount && getCurrentRequestCount() >= maxCount
        #if DEBUG
            if limited {
                let typeName = "\(type(of: self))"
                print("\(typeName) Is Limited")
            }
        #endif
        return limited
    }
    
    fileprivate func getCurrentRequestCount() -> Int32
    {
        let typeName = "\(type(of: self))"
        var result:Int32 = 0
        BahamutRFRequestBase.lock.lock()
        if let value = BahamutRFRequestBase.requestCount[typeName]
        {
            result = value
        }
        BahamutRFRequestBase.lock.unlock()
        return result
    }
}
