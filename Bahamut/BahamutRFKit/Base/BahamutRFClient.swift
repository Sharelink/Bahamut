//
//  BahamutRFClient.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire
import AlamofireJsonToObjects

open class ClientProtocal
{
    func setClientStart(){}
    func setClientClose(){}
    
    @discardableResult
    func execute<T:EVObject>(_ request:BahamutRFRequestBase,callback:@escaping (_ result:SLResult<T>)->Void) -> Bool{ return false }
    
    @discardableResult
    func execute<T:EVObject>(_ request:BahamutRFRequestBase,callback:@escaping (_ result:SLResult<[T]>)->Void) -> Bool{ return false }
    
    @discardableResult
    func execute(_ request:BahamutRFRequestBase,callback:@escaping (_ result:Result<String>)->Void) -> Bool{ return false }
}

public protocol BahamutRFClientDelegate{
    
    func bahamutClientWillSetHeaders(_ client:BahamutRFClient,request:BahamutRFRequestBase)
    func bahamutClientWillSetApi(_ client:BahamutRFClient,request:BahamutRFRequestBase)
    func bahamutClientDidSetHeaders(_ client:BahamutRFClient,request:BahamutRFRequestBase)
    func bahamutClientDidSetApi(_ client:BahamutRFClient,request:BahamutRFRequestBase)
    func bahamutClientWillPerformRequest(_ client:BahamutRFClient,request:BahamutRFRequestBase)
    
}

open class SLResult<T>
{
    open var originResult:Result<T>!;
    open var returnObject:T!{
        return originResult?.value ?? nil
    }
    open var statusCode:Int!;
    open var isFailure:Bool{
        return originResult?.isFailure ?? true
    }
    
    open var isSuccess:Bool{
        return originResult?.isSuccess ?? false
    }
    
    var request:BahamutRFRequestBase!
    
}

open class BahamutRFClient : ClientProtocal
{
    
    open var delegate:BahamutRFClientDelegate?
    
    open fileprivate(set) var userId:String
    open fileprivate(set) var token:String
    open fileprivate(set) var apiServer:String
    fileprivate var clientStarted:Bool = false
    
    init(apiServer:String, userId:String, token:String)
    {
        self.apiServer = apiServer
        self.userId = userId
        self.token = token
    }
    
    override init()
    {
        self.apiServer = ""
        self.userId = ""
        self.token = ""
    }
    
    open override func setClientClose()
    {
        clientStarted = false
    }
    
    open override func setClientStart()
    {
        clientStarted = true
    }
    
    @discardableResult
    func setReqHeader(_ req:BahamutRFRequestBase) -> BahamutRFRequestBase
    {
        req.headers.updateValue(userId, forKey: "userId")
        req.headers.updateValue(token, forKey: "token")
        req.headers["ver"] = BahamutRFKit.appVersion
        req.headers["build"] = "\(BahamutRFKit.appVersionCode)"
        req.headers["pm"] = BahamutRFKit.platform
        return req
    }
    
    fileprivate func setReqApi(_ req:BahamutRFRequestBase)
    {
        req.api = req.apiServerUrl != nil ? req.apiServerUrl + req.api : self.apiServer + req.api
    }
    
    @discardableResult
    public override func execute(_ request: BahamutRFRequestBase, callback: @escaping (_ result: Result<String>) -> Void) -> Bool
    {
        if clientStarted == false || request.isRequestLimited()
        {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "concurrent request times limit"]
            let res = Result<String>.failure(NSError.init(domain: "BahamutRFClient", code: 403, userInfo: userInfo))
            callback(res)
            return false
        }
        request.incRequest()
        
        delegate?.bahamutClientWillSetApi(self, request: request)
        setReqApi(request)
        delegate?.bahamutClientDidSetApi(self, request: request)
        
        delegate?.bahamutClientWillSetHeaders(self, request: request)
        setReqHeader(request)
        delegate?.bahamutClientDidSetHeaders(self, request: request)
        
        let queue = DispatchQueue.global()
        delegate?.bahamutClientWillPerformRequest(self, request: request)
        
        let req = Alamofire.request(request.api, method: request.method, parameters: request.paramenters, encoding: request.encoding, headers: request.headers).validate(contentType: ["application/json"])
        
        req.responseString(queue: queue) { (response) in
            request.decRequest()
            if self.clientStarted == false
            {
                return
            }
            
            DispatchQueue.main.async {
                callback(response.result)
            }
            
            if response.response?.statusCode == 401{
                BahamutRFKit.sharedInstance.postNotificationNameWithMainAsync(BahamutRFKit.onTokenInvalidated, object: BahamutRFKit.sharedInstance, userInfo: nil)
            }
        }
        return true
    }
    
    @discardableResult
    public override func execute<T : EVObject>(_ request: BahamutRFRequestBase, callback: @escaping (SLResult<T>) -> Void) -> Bool{
        if  clientStarted == false || request.isRequestLimited()
        {
            let err = SLResult<T>()
            let userInfo = [NSLocalizedFailureReasonErrorKey: "concurrent request times limit"]
            let res = Result<T>.failure(NSError.init(domain: "BahamutRFClient", code: 403, userInfo: userInfo))
            err.originResult = res
            callback(err)
            return false
        }
        request.incRequest()
        delegate?.bahamutClientWillSetApi(self, request: request)
        setReqApi(request)
        delegate?.bahamutClientDidSetApi(self, request: request)
        
        delegate?.bahamutClientWillSetHeaders(self, request: request)
        setReqHeader(request)
        delegate?.bahamutClientDidSetHeaders(self, request: request)
        
        let queue = DispatchQueue.global()
        delegate?.bahamutClientWillPerformRequest(self, request: request)
        
        let req = Alamofire.request(request.api,method: request.method,  parameters: request.paramenters, encoding: request.encoding, headers: request.headers).validate(contentType: ["application/json"])
        req.responseObject(queue: queue) { (result:DataResponse<T>) in
            request.decRequest()
            if self.clientStarted == false
            {
                return
            }
            let slResult = SLResult<T>()
            slResult.request = request
            slResult.originResult = result.result
            if let responseCode = result.response?.statusCode
            {
                slResult.statusCode = responseCode
            }else{
                slResult.statusCode = 999
            }
            
            DispatchQueue.main.async {
                callback(slResult)
            }
            
            if result.response?.statusCode == 401{
                BahamutRFKit.sharedInstance.postNotificationNameWithMainAsync(BahamutRFKit.onTokenInvalidated, object: BahamutRFKit.sharedInstance, userInfo: nil)
            }
        }
        return true
    }
    
    @discardableResult
    public override func execute<T : EVObject>(_ request: BahamutRFRequestBase, callback: @escaping (SLResult<[T]>) -> Void) -> Bool{
        if clientStarted == false || request.isRequestLimited()
        {
            let err = SLResult<[T]>()
            let userInfo = [NSLocalizedFailureReasonErrorKey: "concurrent request times limit"]
            err.originResult = Result<[T]>.failure(NSError.init(domain: "BahamutRFClient", code: 403, userInfo: userInfo))
            callback(err)
            return false
        }
        request.incRequest()
        delegate?.bahamutClientWillSetApi(self, request: request)
        setReqApi(request)
        delegate?.bahamutClientDidSetApi(self, request: request)
        
        delegate?.bahamutClientWillSetHeaders(self, request: request)
        setReqHeader(request)
        delegate?.bahamutClientDidSetHeaders(self, request: request)
        
        let queue = DispatchQueue.global()
        delegate?.bahamutClientWillPerformRequest(self, request: request)
        
        let req = Alamofire.request(request.api,method:request.method,  parameters: request.paramenters, encoding: request.encoding, headers: request.headers).validate(contentType: ["application/json"])
        req.responseArray(queue: queue) { (result:DataResponse<[T]>) -> Void in
            request.decRequest()
            if self.clientStarted == false
            {
                return
            }
            
            let slResult = SLResult<[T]>()
            slResult.request = request
            slResult.originResult = result.result
            if let responseCode = result.response?.statusCode
            {
                slResult.statusCode = responseCode
            }else{
                slResult.statusCode = 999
            }
            
            DispatchQueue.main.async {
                callback(slResult)
            }
            
            if result.response?.statusCode == 401{
                BahamutRFKit.sharedInstance.postNotificationNameWithMainAsync(BahamutRFKit.onTokenInvalidated, object: BahamutRFKit.sharedInstance, userInfo: nil)
            }
        }
        
        return true
    }
 
}
