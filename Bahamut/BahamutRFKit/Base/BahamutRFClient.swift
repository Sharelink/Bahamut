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

public protocol ClientProtocal
{
    func setClientStart()
    func setClientClose()
    func execute<T:EVObject>(request:BahamutRFRequestBase,callback:(result:SLResult<T>)->Void) -> Bool
    func execute<T:EVObject>(request:BahamutRFRequestBase,callback:(result:SLResult<[T]>)->Void) -> Bool
    
    func execute(request:BahamutRFRequestBase,callback:(result:Result<String,NSError>)->Void) -> Bool
}

public class SLResult<T>
{
    public var originResult:Result<T,NSError>!;
    public var returnObject:T!{
        return originResult?.value ?? nil
    }
    public var statusCode:Int!;
    public var isFailure:Bool{
        return originResult?.isFailure ?? true
    }
    
    public var isSuccess:Bool{
        return originResult?.isSuccess ?? false
    }
}

public class BahamutRFClient : ClientProtocal
{
    public private(set) var userId:String
    public private(set) var token:String
    public private(set) var apiServer:String
    private var clientStarted:Bool = false
    
    init(apiServer:String, userId:String, token:String)
    {
        self.apiServer = apiServer
        self.userId = userId
        self.token = token
    }
    
    init()
    {
        self.apiServer = ""
        self.userId = ""
        self.token = ""
    }
    
    public func setClientClose()
    {
        clientStarted = false
    }
    
    public func setClientStart()
    {
        clientStarted = true
    }
    
    func setReqHeader(req:BahamutRFRequestBase) -> BahamutRFRequestBase
    {
        req.headers.updateValue(userId, forKey: "userId")
        req.headers.updateValue(token, forKey: "token")
        req.version = BahamutRFKit.version
        return req
    }
    
    private func setReqApi(req:BahamutRFRequestBase)
    {
        req.api = req.apiServerUrl != nil ? req.apiServerUrl + req.api : self.apiServer + req.api
    }
    
    public func execute(request: BahamutRFRequestBase, callback: (result: Result<String,NSError>) -> Void) -> Bool
    {
        if clientStarted == false || request.getCurrentRequestCount() >= request.getMaxRequestCount()
        {
            let error = Error.errorWithCode(Error.Code.StatusCodeValidationFailed, failureReason: "concurrent request times limit")
            let res = Result<String,NSError>.Failure(error)
            callback(result: res)
            return false
        }
        request.incRequest()
        setReqApi(request)
        setReqHeader(request)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            Alamofire.request(request.method, request.api, parameters: request.paramenters, encoding: request.encoding, headers: request.headers).validate().validate(contentType: ["application/json"]).responseString(completionHandler: { (response) -> Void in
                request.decRequest()
                if self.clientStarted == false
                {
                    return
                }
                callback(result: response.result)
            })
        }
        return true
    }
    
    public func execute<T:EVObject>(request:BahamutRFRequestBase,callback:(result:SLResult<[T]>)->Void) -> Bool
    {
        if clientStarted == false || request.getCurrentRequestCount() >= request.getMaxRequestCount()
        {
            let err = SLResult<[T]>()
            let error = Error.errorWithCode(Error.Code.StatusCodeValidationFailed, failureReason: "concurrent request times limit")
            err.originResult = Result<[T],NSError>.Failure(error)
            err.originResult = nil
            callback(result: err)
            return false
        }
        request.incRequest()
        setReqApi(request)
        setReqHeader(request)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            Alamofire.request(request.method, request.api, parameters: request.paramenters, encoding: request.encoding, headers: request.headers).validate().validate(contentType: ["application/json"]).responseArray { (_, response, result:Result<[T],NSError>) -> Void in
                request.decRequest()
                if self.clientStarted == false
                {
                    return
                }
                let slResult = SLResult<[T]>()
                slResult.originResult = result
                if let responseCode = response?.statusCode
                {
                    slResult.statusCode = responseCode
                }else{
                    slResult.statusCode = 999
                }
                callback(result: slResult)
            }
        }
        return true
    }
    
    public func execute<T:EVObject>(request:BahamutRFRequestBase,callback:(result:SLResult<T>)->Void) -> Bool
    {
        if  clientStarted == false || request.getCurrentRequestCount() >= request.getMaxRequestCount()
        {
            let err = SLResult<T>()
            let error = Error.errorWithCode(Error.Code.StatusCodeValidationFailed, failureReason: "concurrent request times limit")
            err.originResult = Result<T,NSError>.Failure(error)
            err.originResult = nil
            callback(result: err)
            return false
        }
        request.incRequest()
        setReqApi(request)
        setReqHeader(request)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            Alamofire.request(request.method, request.api, parameters: request.paramenters, encoding: request.encoding, headers: request.headers).validate().validate(contentType: ["application/json"]).responseObject { (_, response, result:Result<T,NSError>) -> Void in
                request.decRequest()
                if self.clientStarted == false
                {
                    return
                }
                let slResult = SLResult<T>()
                slResult.originResult = result
                if let responseCode = response?.statusCode
                {
                    slResult.statusCode = responseCode
                }else{
                    slResult.statusCode = 999
                }
                callback(result: slResult)
            }
        }
        return true
    }
}