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
        if isUserLogined
        {
            ShareLinkSDK.sharedInstance.reuse(userId, token: token, shareLinkApiServer: shareLinkApiServer, fileApiServer: fileApiServer)
        }
        
    }
    
    private(set) var lastLoginAccountId:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("lastLoginAccountId") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "lastLoginAccountId")
        }
    }
    
    var isUserLogined:Bool{
        get{
            return NSUserDefaults.standardUserDefaults().boolForKey("isUserLogined")
        }
        set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "isUserLogined")
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
    
    private var shareLinkApiServer:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("shareLinkApiServer") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "shareLinkApiServer")
        }
    }
    
    private var fileApiServer:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("fileApiServer") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "fileApiServer")
        }
    }
    
    func setLogined(userId:String,token:String,shareLinkApiServer:String,fileApiServer:String)
    {
        self.isUserLogined = true
        self.userId = userId
        self.token = token
        self.shareLinkApiServer = shareLinkApiServer
        self.fileApiServer = fileApiServer
    }
    
    func generateSharelinkerQrString() -> String
    {
        return "sharelinker://accountId=\(lastLoginAccountId)"
    }
    
    func getSharelinkerAccountIdFromQRString(qr:String)-> String
    {
        return qr.substringFromIndex("sharelinker://accountId= ".endIndex)
    }
    
    func validateAccessToken(apiTokenServer:String, accountId:String, accessToken: String,callback:(loginSuccess:Bool,message:String)->Void,registCallback:((registApiServer:String!)->Void)! = nil)
    {
        self.lastLoginAccountId = accountId
        ShareLinkSDK.sharedInstance.validateAccessToken(apiTokenServer, accountId: accountId, accessToken: accessToken) { (isNewUser, error, registApiServer) -> Void in
            if isNewUser
            {
                registCallback(registApiServer:registApiServer)
            }else if error == nil{
                let sdk = ShareLinkSDK.sharedInstance
                self.setLogined(sdk.userId, token: sdk.token, shareLinkApiServer: sdk.shareLinkApiServer, fileApiServer: sdk.fileApiServer)
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
            self.isUserLogined = false
            self.userId = nil
            self.token = nil
            self.fileApiServer = nil
            self.shareLinkApiServer = nil
            if let callback = logoutCallback
            {
                callback(message: message)
            }
        }
    }
}