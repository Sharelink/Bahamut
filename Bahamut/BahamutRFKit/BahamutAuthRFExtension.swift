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
            userInfos["accountId"] = newValue
        }
    }
    
    var userId:String!{
        get{
            return userInfos["userId"] as? String
        }
        set{
            userInfos["userId"] = newValue
        }
    }
    
    var token:String!{
        get{
            return userInfos["token"] as? String
        }
        set{
            userInfos["token"] = newValue
        }
    }
    
    
    var chicagoServerHost:String!{
        get{
            return userInfos["chicagoServerHost"] as? String
        }
        set{
            userInfos["chicagoServerHost"] = newValue
        }
    }
    
    var chicagoServerPort:UInt16{
        get{
            return (userInfos["chicagoServerPort"] as? NSNumber)?.unsignedShortValue ?? 0
        }
        set{
            userInfos["chicagoServerPort"] = NSNumber(unsignedShort: newValue)
        }
    }
    
    var tokenApi:String!{
        get{
            return userInfos["tokenApi"] as? String
        }
        set{
            userInfos["tokenApi"] = newValue
        }
    }
    
    func resetUser(userId:String, token:String)
    {
        self.userId = userId
        self.token = token
    }
    
    func useValidateData(validateResult:ValidateResult)
    {
        self.userId = validateResult.userId
        self.token = validateResult.appToken
        self.fileApiServer = validateResult.fileAPIServer
        self.appApiServer = validateResult.apiServer
        let chicagoStrs = validateResult.chicagoServer.split(":")
        self.chicagoServerHost = chicagoStrs[0]
        self.chicagoServerPort = UInt16(chicagoStrs[1])!
    }
    
    func registBahamutAccount(registApi:String, username:String, passwordOrigin:String, phone_number:String!, email:String!,callback:(isSuc:Bool,errorMsg:String!,registResult:RegistResult!)->Void)
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
        Alamofire.request(.POST, registApi, parameters: params).responseObject { (result:Result<RegistResult, NSError>) -> Void in
            if let suc = result.value?.suc
            {
                if suc
                {
                    callback(isSuc: true, errorMsg: nil, registResult: result.value)
                }else
                {
                    callback(isSuc: false, errorMsg: result.value?.msg, registResult: nil)
                }
            }else{
                callback(isSuc: false, errorMsg: "NETWORK_ERROR", registResult: nil)
            }
        }
    }
    
    func loginBahamutAccount(loginApi:String, accountInfo:String, passwordOrigin:String,callback:(isSuc:Bool,errorMsg:String!,loginResult:LoginResult!)->Void)
    {
        let params = ["username":accountInfo,"password":passwordOrigin.sha256,"appkey":BahamutRFKit.appkey]
        Alamofire.request(.POST, loginApi, parameters: params).responseObject { (result:Result<LoginResult, NSError>) -> Void in
            if result.isSuccess{
                if let value = result.value
                {
                    if String.isNullOrEmpty(value.loginSuccessed) == false && "true" == value.loginSuccessed
                    {
                        callback(isSuc: true, errorMsg: nil, loginResult: value)
                    }else
                    {
                        callback(isSuc: false, errorMsg: value.msg ?? "NETWORK_ERROR", loginResult: nil)
                    }
                }else{
                    callback(isSuc: false, errorMsg: "NETWORK_ERROR", loginResult: nil)
                }
            }
            else{
                callback(isSuc: false, errorMsg: result.value?.msg ?? "NETWORK_ERROR", loginResult: nil)
            }
        }
    }
    
    func changeAccountPassword(authServerApi:String,appkey:String, appToken:String,accountId:String,userId:String,originPassword:String,newPassword:String,callback:(suc:Bool,msg:String!)->Void)
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
        Alamofire.request(.PUT, "\(authServerApi)/Password", parameters: params).responseObject { (_, response, result:Result<MsgResult,NSError>) in
            if response?.statusCode == 200
            {
                callback(suc: true, msg: result.value?.msg)
            }else
            {
                callback(suc: false, msg: result.value?.msg ?? "SERVER_ERROR")
            }
        }
    }
    
    func validateAccessToken(tokenApi:String,accountId:String,accessToken:String,callback:(isNewUser:Bool,error:String!,validateResult:ValidateResult! )->Void)
    {
        self.tokenApi = tokenApi
        Alamofire.request(Method.GET, tokenApi, parameters: ["appkey":BahamutRFKit.appkey,"accountId":accountId,"accessToken":accessToken]).responseObject { (req, response,result:Result<ValidateResult,NSError>) -> Void in
            if result.isSuccess
            {
                if let validateResult = result.value
                {
                    if validateResult.isValidateResultDataComplete()
                    {
                        if !String.isNullOrEmpty(validateResult.registAPIServer)
                        {
                            callback(isNewUser: true,error: nil,validateResult: validateResult)
                        }else
                        {
                            self.useValidateData(validateResult)
                            callback(isNewUser: false,error: nil,validateResult: validateResult)
                        }
                    }else
                    {
                        callback(isNewUser: false,error: "VALIDATE_DATA_ERROR",validateResult: nil)
                    }
                }
            }else{
                
                callback(isNewUser: false,error: "NETWORK_ERROR",validateResult: nil)
            }
        }
    }
    
    func cancelToken(finishCallback:(message:String!) ->Void)
    {
        if tokenApi == nil
        {
            finishCallback(message: "NOT_LOGIN")
            return
        }
        Alamofire.request(Method.DELETE, tokenApi, parameters: ["userId":userId,"appToken":token,"appkey":BahamutRFKit.appkey]).responseObject { (result:Result<EVObject,NSError>) -> Void in
            finishCallback(message: "LOGOUTED")
        }
    }
}
