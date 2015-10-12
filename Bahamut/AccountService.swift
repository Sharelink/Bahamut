//
//  AccountService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class AccountService: ServiceProtocol
{
    @objc static var ServiceName:String{return "account service"}
    
    @objc func userLoginInit(userId:String)
    {
        
    }
    
    @objc func appStartInit()
    {
        if BahamutConfig.isUserLogined
        {
            ShareLinkSDK.sharedInstance.reuse(userId, token: token, shareLinkApiServer: BahamutConfig.shareLinkApiServer, fileApiServer: BahamutConfig.fileApiServer)
        }
        
    }
    
    private(set) var userId:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("userId") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "userId")
        }
    }
    
    private(set) var token:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("token") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "token")
        }
    }
    
    func setLogined(validateResult:ValidateResult)
    {
        self.userId = validateResult.UserId
        self.token = validateResult.AppToken
        BahamutConfig.isUserLogined = true
        BahamutConfig.shareLinkApiServer = validateResult.APIServer
        BahamutConfig.fileApiServer = validateResult.FileAPIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        BahamutConfig.chicagoServerHost = chicagoStrs[0]
        BahamutConfig.chicagoServerHostPort = UInt16(chicagoStrs[1])!
    }
    
    func generateSharelinkerQrString() -> String
    {
        return "sharelinker://accountId=\(BahamutConfig.lastLoginAccountId)"
    }
    
    func getSharelinkerAccountIdFromQRString(qr:String)-> String
    {
        return qr.substringFromIndex("sharelinker://accountId= ".endIndex)
    }
    
    func validateAccessToken(apiTokenServer:String, accountId:String, accessToken: String,callback:(loginSuccess:Bool,message:String)->Void,registCallback:((registApiServer:String!)->Void)! = nil)
    {
        BahamutConfig.lastLoginAccountId = accountId
        ShareLinkSDK.sharedInstance.validateAccessToken(apiTokenServer, accountId: accountId, accessToken: accessToken) { (isNewUser, error, registApiServer,validateResult) -> Void in
            if isNewUser
            {
                registCallback(registApiServer:registApiServer)
            }else if error == nil{
                self.setLogined(validateResult)
                callback(loginSuccess: true, message: "Validate AccessToken Success")
            }else{
                callback(loginSuccess: false, message: error)
            }
            
        }
    }
    
    func logout(logoutCallback:((message:String)->Void)! = nil)
    {

        ShareLinkSDK.sharedInstance.cancelToken(){
            message in
            self.userId = nil
            self.token = nil
            BahamutConfig.isUserLogined = false
            BahamutConfig.fileApiServer = nil
            BahamutConfig.shareLinkApiServer = nil
            BahamutConfig.chicagoServerHost = nil
            BahamutConfig.chicagoServerHostPort = 0
            if let callback = logoutCallback
            {
                callback(message: message)
            }
        }
    }
}