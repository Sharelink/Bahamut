//
//  BahamutAuthRFExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/27.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

//MARK: Auth models
class MsgResult:BahamutObject
{
    var code:Int = 0
    var msg:String!
}

class RegistResult:MsgResult
{
    var suc:Bool = false
    
    //regist info
    var accountId:String!
    var accountName:String!
}

class LoginResult: MsgResult
{
    var loginSuccessed:String!
    var accountID:String!
    var accountName:String!
    var accessToken:String!
    var appServerIP:String!
    var appServerPort:String!
    var appServiceUrl:String!
    var bindMobile:String!
    var bindEmail:String!
    
}

class ValidateResult : EVObject
{
    var Succeed = false
    
    //validate success part
    var userId:String!
    var appToken:String!
    var apiServer:String!
    var fileAPIServer:String!
    var chicagoServer:String!
    
    //new user part
    var registAPIServer:String!
    
    func isValidateResultDataComplete() -> Bool
    {
        if registAPIServer != nil
        {
            return true
        }else
        {
            return (userId != nil &&
                appToken != nil &&
                fileAPIServer != nil &&
                apiServer != nil &&
                chicagoServer != nil
            )
        }
    }
}


//MARK: Bahamut Auth Extension
extension BahamutRFKit
{
    var accountId:String!{
        get{
            return userInfos["accountId"] as? String
        }
        set{
            userInfos["accountId"] = newValue as AnyObject??
        }
    }
    
    var userId:String!{
        get{
            return userInfos["userId"] as? String
        }
        set{
            userInfos["userId"] = newValue as AnyObject??
        }
    }
    
    var token:String!{
        get{
            return userInfos["token"] as? String
        }
        set{
            userInfos["token"] = newValue as AnyObject??
        }
    }
    
    
    var chicagoServerHost:String!{
        get{
            return userInfos["chicagoServerHost"] as? String
        }
        set{
            userInfos["chicagoServerHost"] = newValue as AnyObject??
        }
    }
    
    var chicagoServerPort:UInt16{
        get{
            return (userInfos["chicagoServerPort"] as? NSNumber)?.uint16Value ?? 0
        }
        set{
            userInfos["chicagoServerPort"] = NSNumber(value: newValue as UInt16)
        }
    }
    
    var tokenApi:String!{
        get{
            return userInfos["tokenApi"] as? String
        }
        set{
            userInfos["tokenApi"] = newValue as AnyObject??
        }
    }
    
    func resetUser(_ userId:String, token:String)
    {
        self.userId = userId
        self.token = token
    }
    
    func useValidateData(_ validateResult:ValidateResult)
    {
        self.userId = validateResult.userId
        self.token = validateResult.appToken
        self.fileApiServer = validateResult.fileAPIServer
        self.appApiServer = validateResult.apiServer
        let chicagoStrs = validateResult.chicagoServer.split(":")
        self.chicagoServerHost = chicagoStrs[0]
        self.chicagoServerPort = UInt16(chicagoStrs[1])!
    }
    
    func registBahamutAccount(_ registApi:String, username:String, passwordOrigin:String, phone_number:String!, email:String!,callback:@escaping (_ isSuc:Bool,_ errorMsg:String?,_ registResult:RegistResult?)->Void)
    {
        var params = ["username":username,"password":passwordOrigin.sha256,"appkey":BahamutRFKit.appkey]
        if String.isNullOrWhiteSpace(phone_number) == false
        {
            params["phone_number"] = phone_number
        }
        if String.isNullOrWhiteSpace(email) == false
        {
            params["email"] = email
        }
        Alamofire.request(registApi, method: .post, parameters: params, encoding: URLEncoding.default, headers: nil).responseObject { (result:DataResponse<RegistResult>) in
            if let suc = result.value?.suc
            {
                if suc
                {
                    callback(true, nil, result.value)
                }else
                {
                    callback(false, result.value?.msg, nil)
                }
            }else{
                callback(false, "NETWORK_ERROR", nil)
            }
        }
    }
    
    func loginBahamutAccount(_ loginApi:String, accountInfo:String, passwordOrigin:String,callback:@escaping (_ isSuc:Bool,_ errorMsg:String?,_ loginResult:LoginResult?)->Void)
    {
        let params = ["username":accountInfo,"password":passwordOrigin.sha256,"appkey":BahamutRFKit.appkey]
        Alamofire.request(loginApi, method: .post, parameters: params, encoding: URLEncoding.default, headers: nil).responseObject { (result:DataResponse<LoginResult>) -> Void in
            if result.result.isSuccess{
                if let value = result.value
                {
                    if String.isNullOrEmpty(value.loginSuccessed) == false && "true" == value.loginSuccessed
                    {
                        callback(true, nil, value)
                    }else
                    {
                        callback(false, value.msg ?? "NETWORK_ERROR", nil)
                    }
                }else{
                    callback(false, "NETWORK_ERROR", nil)
                }
            }
            else{
                callback(false, result.value?.msg ?? "NETWORK_ERROR", nil)
            }
        }
    }
    
    func changeAccountPassword(_ authServerApi:String,appkey:String, appToken:String,accountId:String,userId:String,originPassword:String,newPassword:String,callback:@escaping (_ suc:Bool,_ msg:String?)->Void)
    {
        let params =
            [
                "appkey":appkey,
                "appToken":appToken,
                "accountId":accountId,
                "userId":userId,
                "originPassword":originPassword.sha256,
                "newPassword":newPassword.sha256
        ]
        let urlString = "\(authServerApi)/Password"
        
        Alamofire.request(urlString, method: .put, parameters: params, encoding: URLEncoding.default, headers: nil).responseObject { (result:DataResponse<MsgResult>) in
            
            if result.response?.statusCode == 200
            {
                callback(true, result.value?.msg)
            }else
            {
                callback(false, result.value?.msg ?? "SERVER_ERROR")
            }
        }
    }
    
    func validateAccessToken(_ tokenApi:String,accountId:String,accessToken:String,callback:@escaping (_ isNewUser:Bool,_ error:String?,_ validateResult:ValidateResult?)->Void)
    {
        self.tokenApi = tokenApi
        let params = ["appkey":BahamutRFKit.appkey,"accountId":accountId,"accessToken":accessToken]
        Alamofire.request(tokenApi, method: .get, parameters: params, encoding: URLEncoding.default, headers: nil).responseObject { (result:DataResponse<ValidateResult>) -> Void in
            if result.result.isSuccess
            {
                if let validateResult = result.value
                {
                    if validateResult.isValidateResultDataComplete()
                    {
                        if !String.isNullOrEmpty(validateResult.registAPIServer)
                        {
                            callback(true,nil,validateResult)
                        }else
                        {
                            self.useValidateData(validateResult)
                            callback(false,nil,validateResult)
                        }
                    }else
                    {
                        callback(false,"VALIDATE_DATA_ERROR",nil)
                    }
                }
            }else{
                
                callback(false,"NETWORK_ERROR",nil)
            }
        }
    }
    
    func cancelToken(_ finishCallback:@escaping (_ message:String?) ->Void)
    {
        if tokenApi == nil
        {
            finishCallback("NOT_LOGIN")
            return
        }
        let params = ["userId":userId,"appToken":token,"appkey":BahamutRFKit.appkey]
        Alamofire.request(tokenApi, method: .delete, parameters: params, encoding: URLEncoding.default, headers: nil).responseObject { (result:DataResponse<EVObject>) in
            finishCallback("LOGOUTED")
        }
    }
}
