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

let ShareLinkClientType = "ShareLinkClientType"
let BahamutFireClientType = "BahamutFireClientType"

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
    
    func validateAccessToken(apiTokenServer:String,accountId:String,accessToken:String,callback:(isNewUser:Bool,error:String!,registApiServer:String!,validateResult:ValidateResult! )->Void)
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
                            callback(isNewUser: true,error: nil,registApiServer:validateResult.RegistAPIServer!,validateResult: nil)
                        }else
                        {
                            self.useValidateData(validateResult)
                            callback(isNewUser: false,error: nil,registApiServer:nil,validateResult: validateResult)
                        }
                    }else
                    {
                        callback(isNewUser: false,error: "VALIDATE_DATA_ERROR".localizedString(),registApiServer:nil,validateResult: nil)
                    }
                }
            }else{
                
                callback(isNewUser: false,error: "NETWORK_ERROR".localizedString(),registApiServer:nil,validateResult: nil)
            }
        }
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