//
//  ShareLinkSDKRequestBase.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

public class ShareLinkSDKRequestBase : NSObject
{
    static var requestCount = [String:Int32]()
    static let lock:NSRecursiveLock = NSRecursiveLock()
    
    public func getMaxRequestCount() -> Int32{
        return 1
    }
    public func incRequest()
    {
        let typeName = self.classForCoder.description()
        ShareLinkSDKRequestBase.lock.lock()
        ShareLinkSDKRequestBase.requestCount[typeName] = getCurrentRequestCount() + 1
        ShareLinkSDKRequestBase.lock.unlock()
    }
    
    public func decRequest()
    {
        let typeName = self.classForCoder.description()
        ShareLinkSDKRequestBase.lock.lock()
        ShareLinkSDKRequestBase.requestCount[typeName] = getCurrentRequestCount() - 1
        ShareLinkSDKRequestBase.lock.unlock()
    }
    
    public func getCurrentRequestCount() -> Int32
    {
        let typeName = self.classForCoder.description()
        var result:Int32 = 0
        ShareLinkSDKRequestBase.lock.lock()
        if let value = ShareLinkSDKRequestBase.requestCount[typeName]
        {
            result = value
        }
        ShareLinkSDKRequestBase.lock.unlock()
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