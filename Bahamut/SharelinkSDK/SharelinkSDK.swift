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

public class ValidateResult : EVObject
{
    //validate success part
    public var UserId:String!
    public var AppToken:String!
    public var APIServer:String!
    public var FileAPIServer:String!
    public var ChicagoServer:String!
    
    //new user part
    public var RegistAPIServer:String!
    
    public func isValidateResultDataComplete() -> Bool
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

public let ShareLinkClientType = "ShareLinkClientType"
public let BahamutFireClientType = "BahamutFireClientType"

public class SharelinkSDK
{
    public static let appkey = "5e6c827f2fcb04e8fca80cf72db5ba004508246b";
    public private(set) static var version:String = "1.0"
    public private(set) var accountId:String!
    public private(set) var userId:String!
    public private(set) var token:String!
    public private(set) var fileApiServer:String!
    public private(set) var shareLinkApiServer:String!
    public private(set) var apiTokenServer:String!
    public private(set) var chicagoServerHost:String!
    public private(set) var chicagoServerPort:UInt16 = 0
    
    private var clients:[String:ClientProtocal] = [String:ClientProtocal]()
    
    private init(){}
    
    public static let sharedInstance: SharelinkSDK = {
        return SharelinkSDK()
    }()
    
    public static func setAppVersion(version:String)
    {
        SharelinkSDK.version = version
    }
    
    public func reuse(userId:String,token:String!,shareLinkApiServer:String,fileApiServer:String)
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
    
    public func startClients()
    {
        for client in clients.values
        {
            client.setClientStart()
        }
    }
    
    public func closeClients()
    {
        for client in clients.values
        {
            client.setClientClose()
        }
    }

    public func useValidateData(validateResult:ValidateResult)
    {
        self.userId = validateResult.UserId
        self.token = validateResult.AppToken
        self.fileApiServer = validateResult.FileAPIServer
        self.shareLinkApiServer = validateResult.APIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        self.chicagoServerHost = chicagoStrs[0]
        self.chicagoServerPort = UInt16(chicagoStrs[1])!
    }
    
    public func validateAccessToken(apiTokenServer:String,accountId:String,accessToken:String,callback:(isNewUser:Bool,error:String!,registApiServer:String!,validateResult:ValidateResult! )->Void)
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
                        callback(isNewUser: false,error: NSLocalizedString("VALIDATE_DATA_ERROR", comment: "Validate Data Error"),registApiServer:nil,validateResult: nil)
                    }
                }
            }else{
                
                callback(isNewUser: false,error: NSLocalizedString("NETWORK_ERROR", comment: "Network Error"),registApiServer:nil,validateResult: nil)
            }
        }
    }
    
    public func cancelToken(finishCallback:(message:String!) ->Void)
    {
        if apiTokenServer == nil
        {
            finishCallback(message: NSLocalizedString("NOT_LOGIN", comment: "Not Login"))
            return
        }
        Alamofire.request(Method.DELETE, "\(apiTokenServer)/Tokens", parameters: ["userId":userId,"appToken":token,"appkey":SharelinkSDK.appkey]).responseObject { (result:Result<EVObject,NSError>) -> Void in
            finishCallback(message: NSLocalizedString("LOGOUTED", comment: "Logout"))
        }
    }
    
    public func getBahamutClient() -> ClientProtocal
    {
        let client = ShareLinkSDKClient()
        client.setClientStart()
        return client
    }
    
    public func getShareLinkClient() -> ClientProtocal
    {
        return clients[ShareLinkClientType]!
    }
    
    public func getBahamutFireClient() -> BahamutFireClient
    {
        return clients[BahamutFireClientType] as! BahamutFireClient
    }
}