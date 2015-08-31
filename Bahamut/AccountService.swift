//
//  AccountService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class AccountService: ServiceProtocol
{
    @objc static var ServiceName:String{return "account service"}
    @objc func initService() {
        if isUserLogined
        {
            ShareLinkSDK.sharedInstance.reuse(userId, token: token, shareLinkApiServer: shareLinkApiServer, fileApiServer: fileApiServer)
        }
        
    }
    let authenticationURL: String = "http://192.168.0.168:8086"
    
    private(set) var isUserLogined:Bool{
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
    
    func logined(userId:String,token:String,shareLinkApiServer:String,fileApiServer:String,callback:(()->Void)! = nil)
    {
        self.isUserLogined = true
        self.userId = userId
        self.token = token
        self.shareLinkApiServer = shareLinkApiServer
        self.fileApiServer = fileApiServer
        if let handler = callback
        {
            handler()
        }
    }
    
    func registAccount(userName:String,password:String,registCallback:(accountId:String!,userId:String!,token:String!,sharelinkApiServer:String!,fileApiServer:String!,error:String!)->Void)
    {
        //TODO: modify here
        registCallback(accountId: "715488548", userId: "147258", token: "qwertyuiopasdfghjklzxcvbnm", sharelinkApiServer:"https://api.sharelink.com",fileApiServer:"https://fileApi.sharelink.com",error: nil)
    }
    
    func logout(logoutCallback:((isSuc:Bool,msg:String)->Void)! = nil)
    {

        ShareLinkSDK.sharedInstance.cancelToken(){
            error in
            self.isUserLogined = false
            self.userId = nil
            self.token = nil
            self.fileApiServer = nil
            self.shareLinkApiServer = nil
            if let callback = logoutCallback
            {
                callback(isSuc: error == nil, msg: error)
            }
        }
    }
}