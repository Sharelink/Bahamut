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
class BahamutRFKit
{
    static var appkey = "no_key"
    private(set) static var version:String = "1.0"
    private(set) var accountId:String!
    private(set) var userId:String!
    private(set) var token:String!
    private(set) var fileApiServer:String!
    private(set) var appApiServer:String!
    private(set) var tokenApi:String!
    private(set) var chicagoServerHost:String!
    private(set) var chicagoServerPort:UInt16 = 0
    
    private var clients:[String:ClientProtocal] = [String:ClientProtocal]()
    
    private init(){}
    
    static let sharedInstance: BahamutRFKit = {
        return BahamutRFKit()
    }()
    
    static func setAppVersion(version:String)
    {
        BahamutRFKit.version = version
    }
    
    func reuse(userId:String,token:String!,appApiServer:String,fileApiServer:String)
    {
        self.userId = userId
        self.token = token
        self.fileApiServer = fileApiServer
        self.appApiServer = appApiServer
        clients.removeAll()
        let sharelinkClient = BahamutRFClient(apiServer:self.appApiServer,userId:self.userId,token:self.token)
        clients.updateValue(sharelinkClient, forKey: BahamutRFClientType)
        
        let fileClient = BahamutFireClient(fileApiServer:self.fileApiServer,userId:self.userId,token:self.token)
        clients.updateValue(fileClient, forKey: BahamutFireClientType)
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
    }

    func useValidateData(validateResult:ValidateResult)
    {
        self.userId = validateResult.UserId
        self.token = validateResult.AppToken
        self.fileApiServer = validateResult.FileAPIServer
        self.appApiServer = validateResult.APIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
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
        let client = BahamutRFClient()
        client.setClientStart()
        return client
    }
    
    func getShareLinkClient() -> ClientProtocal
    {
        return clients[BahamutRFClientType]!
    }
    
    func getBahamutFireClient() -> BahamutFireClient
    {
        return clients[BahamutFireClientType] as! BahamutFireClient
    }
    
}

//MARK: Auth models
class RegistResult:EVObject
{
    var suc:Bool = false
    var msg:String!
    
    //regist info
    var accountId:String!
    var accountName:String!
}

class LoginResult: EVObject
{
    var LoginSuccessed:String!
    var AccountID:String!
    var AccountName:String!
    var AccessToken:String!
    var AppServerIP:String!
    var AppServerPort:String!
    var AppServiceUrl:String!
    
    //error msg
    var msg:String!
}

class ValidateResult : EVObject
{
    //validate success part
    var UserId:String!
    var AppToken:String!
    var APIServer:String!
    var FileAPIServer:String!
    var ChicagoServer:String!
    
    //new user part
    var RegistAPIServer:String!
    
    func isValidateResultDataComplete() -> Bool
    {
        if RegistAPIServer != nil
        {
            return true
        }else
        {
            return (UserId != nil &&
                AppToken != nil &&
                FileAPIServer != nil &&
                APIServer != nil &&
                ChicagoServer != nil
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
            if let value = result.value
            {
                if String.isNullOrEmpty(value.LoginSuccessed) == false && "true" == value.LoginSuccessed
                {
                    callback(isSuc: true, errorMsg: nil, loginResult: value)
                }else
                {
                    callback(isSuc: false, errorMsg: value.msg, loginResult: nil)
                }
            }else{
                callback(isSuc: false, errorMsg: "NETWORK_ERROR", loginResult: nil)
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
                        if validateResult.RegistAPIServer != nil
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