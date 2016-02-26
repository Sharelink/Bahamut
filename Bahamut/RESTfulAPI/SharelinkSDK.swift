//
//  SharelinkSDK.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

let ShareLinkClientType = "ShareLinkClientType"
let BahamutFireClientType = "BahamutFireClientType"

//MARK: SharelinkSDK
class SharelinkSDK
{
    static let appkey = "5e6c827f2fcb04e8fca80cf72db5ba004508246b";
    private(set) static var version:String = "1.0"
    private(set) var accountId:String!
    private(set) var userId:String!
    private(set) var token:String!
    private(set) var fileApiServer:String!
    private(set) var shareLinkApiServer:String!
    private(set) var apiTokenServer:String!
    private(set) var chicagoServerHost:String!
    private(set) var chicagoServerPort:UInt16 = 0
    
    private var clients:[String:ClientProtocal] = [String:ClientProtocal]()
    
    private init(){}
    
    static let sharedInstance: SharelinkSDK = {
        return SharelinkSDK()
    }()
    
    static func setAppVersion(version:String)
    {
        SharelinkSDK.version = version
    }
    
    func reuse(userId:String,token:String!,shareLinkApiServer:String,fileApiServer:String)
    {
        self.userId = userId
        self.token = token
        self.fileApiServer = fileApiServer
        self.shareLinkApiServer = shareLinkApiServer
        clients.removeAll()
        let sharelinkClient = ShareLinkSDKClient(apiServer:self.shareLinkApiServer,userId:self.userId,token:self.token)
        clients.updateValue(sharelinkClient, forKey: ShareLinkClientType)
        
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
        self.shareLinkApiServer = validateResult.APIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        self.chicagoServerHost = chicagoStrs[0]
        self.chicagoServerPort = UInt16(chicagoStrs[1])!
    }
    
    func cancelToken(finishCallback:(message:String!) ->Void)
    {
        if apiTokenServer == nil
        {
            finishCallback(message: "NOT_LOGIN".localizedString())
            return
        }
        Alamofire.request(Method.DELETE, "\(apiTokenServer)/Tokens", parameters: ["userId":userId,"appToken":token,"appkey":SharelinkSDK.appkey]).responseObject { (result:Result<EVObject,NSError>) -> Void in
            finishCallback(message: "LOGOUTED".localizedString())
        }
    }
    
    func getBahamutClient() -> ClientProtocal
    {
        let client = ShareLinkSDKClient()
        client.setClientStart()
        return client
    }
    
    func getShareLinkClient() -> ClientProtocal
    {
        return clients[ShareLinkClientType]!
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

//MARK: sharelink sdk auth extension
extension SharelinkSDK
{
    func registBahamutAccount(registApi:String, username:String, passwordOrigin:String, phone_number:String!, email:String!,callback:(isSuc:Bool,errorMsg:String!,registResult:RegistResult!)->Void)
    {
        var params = ["username":username,"password":passwordOrigin.sha256,"appkey":SharelinkSDK.appkey]
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
        let params = ["username":accountInfo,"password":passwordOrigin.sha256,"appkey":SharelinkSDK.appkey]
        Alamofire.request(.POST, loginApi, parameters: params).responseObject { (result:Result<LoginResult, NSError>) -> Void in
            if let value = result.value
            {
                if value.LoginSuccessed == "true"
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
    
    func validateAccessToken(apiTokenServer:String,accountId:String,accessToken:String,callback:(isNewUser:Bool,error:String!,validateResult:ValidateResult! )->Void)
    {
        self.apiTokenServer = apiTokenServer
        Alamofire.request(Method.GET, "\(apiTokenServer)/Tokens", parameters: ["appkey":SharelinkSDK.appkey,"accountId":accountId,"accessToken":accessToken]).responseObject { (req, response,result:Result<ValidateResult,NSError>) -> Void in
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
                        callback(isNewUser: false,error: "VALIDATE_DATA_ERROR".localizedString(),validateResult: nil)
                    }
                }
            }else{
                
                callback(isNewUser: false,error: "NETWORK_ERROR".localizedString(),validateResult: nil)
            }
        }
    }
}