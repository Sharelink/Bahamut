//
//  BahamutRFKit.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

let BahamutRFClientType = "BahamutRFClientType"
let BahamutFireClientType = "BahamutFireClientType"

//MARK: BahamutRFKit
class BahamutRFKit:NSNotificationCenter
{
    static let onTokenInvalidated = "onTokenInvalidated"
    static var appkey = "no_key"
    private(set) static var appVersion:String = "1.0"
    private(set) var accountId:String!
    private(set) var userId:String!
    private(set) var token:String!
    private(set) var fileApiServer:String!
    private(set) var appApiServer:String!
    private(set) var tokenApi:String!
    private(set) var chicagoServerHost:String!
    private(set) var chicagoServerPort:UInt16 = 0
    
    private var clients:[String:ClientProtocal] = [String:ClientProtocal]()
    
    static let sharedInstance: BahamutRFKit = {
        return BahamutRFKit()
    }()
    
    static func setRFKitAppVersion(version:String)
    {
        BahamutRFKit.appVersion = version
    }
    
    func reuseApiServer(userId:String, token:String,appApiServer:String)
    {
        self.appApiServer = appApiServer
        let client = BahamutRFClient(apiServer:self.appApiServer,userId:userId,token:token)
        clients.updateValue(client, forKey: BahamutRFClientType)
    }
    
    func reuseFileApiServer(userId:String, token:String,fileApiServer:String)
    {
        self.fileApiServer = fileApiServer
        let fileClient = BahamutFireClient(fileApiServer:self.fileApiServer,userId:userId,token:token)
        clients.updateValue(fileClient, forKey: BahamutFireClientType)
    }
    
    func resetUser(userId:String, token:String)
    {
        self.userId = userId
        self.token = token
    }
    
    func startClients()
    {
        for client in clients.values
        {
            client.setClientStart()
        }
    }
    
    func closeClients()
    {
        for client in clients.values
        {
            client.setClientClose()
        }
        clients.removeAll()
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
    
    func getBahamutClient() -> ClientProtocal
    {
        if let client =  clients[BahamutRFClientType]{
            return client
        }
        let client = BahamutRFClient()
        client.setClientStart()
        return client
    }
    
    func getBahamutFireClient() -> BahamutFireClient
    {
        return clients[BahamutFireClientType] as! BahamutFireClient
    }
    
}

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
        Alamofire.request(.PUT, "\(authServerApi)/Password", parameters: params).responseObject { (result:Result<MsgResult, NSError>) -> Void in
            if result.isSuccess
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
}