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
        ShareLinkSDK.sharedInstance.reuse(BahamutConfig.userId, token: BahamutConfig.token, shareLinkApiServer: BahamutConfig.shareLinkApiServer, fileApiServer: BahamutConfig.fileApiServer)
        ShareLinkSDK.sharedInstance.startClients()
    }
    
    @objc func userLogout(userId: String) {
        BahamutConfig.token = nil
        BahamutConfig.isUserLogined = false
        BahamutConfig.fileApiServer = nil
        BahamutConfig.shareLinkApiServer = nil
        BahamutConfig.chicagoServerHost = nil
        BahamutConfig.chicagoServerHostPort = 0
        BahamutConfig.userId = nil
        ShareLinkSDK.sharedInstance.cancelToken(){
            message in
            
        }
        ShareLinkSDK.sharedInstance.closeClients()
    }
    
    @objc func appStartInit()
    {

    }
    
    private func setLogined(validateResult:ValidateResult)
    {
        BahamutConfig.token = validateResult.AppToken
        BahamutConfig.isUserLogined = true
        BahamutConfig.shareLinkApiServer = validateResult.APIServer
        BahamutConfig.fileApiServer = validateResult.FileAPIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        BahamutConfig.chicagoServerHost = chicagoStrs[0]
        BahamutConfig.chicagoServerHostPort = UInt16(chicagoStrs[1])!
        BahamutConfig.userId = validateResult.UserId
        ServiceContainer.instance.userLogin(validateResult.UserId)
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
    
    func registNewUser(registModel:RegistModel,newUser:ShareLinkUser,callback:(isSuc:Bool,msg:String,validateResult:ValidateResult!)->Void)
    {
        let req = RegistNewSharelinkUserRequest()
        req.nickName = newUser.nickName
        req.motto = newUser.motto
        req.accessToken = registModel.accessToken
        req.accountId = registModel.accountId
        req.apiServerUrl = registModel.registUserServer
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ValidateResult>) -> Void in
            if result.isFailure
            {
                callback(isSuc:false,msg:"Regist Failed",validateResult: nil);
            }else if let validateResult = result.returnObject
            {
                if validateResult.isValidateResultDataComplete()
                {
                    ShareLinkSDK.sharedInstance.useValidateData(validateResult)
                    self.setLogined(validateResult)
                    callback(isSuc: true, msg: "regist success",validateResult:validateResult)
                }else
                {
                    callback(isSuc: false, msg: "Data Error",validateResult:nil)
                }
            }else
            {
                callback(isSuc:false,msg:"Regist Failed",validateResult:nil);
            }
        }
    }
}