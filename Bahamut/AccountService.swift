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
        ShareLinkSDK.sharedInstance.reuse(BahamutSetting.userId, token: BahamutSetting.token, shareLinkApiServer: BahamutSetting.shareLinkApiServer, fileApiServer: BahamutSetting.fileApiServer)
        ShareLinkSDK.sharedInstance.startClients()
    }
    
    @objc func userLogout(userId: String) {
        BahamutSetting.token = nil
        BahamutSetting.isUserLogined = false
        BahamutSetting.fileApiServer = nil
        BahamutSetting.shareLinkApiServer = nil
        BahamutSetting.chicagoServerHost = nil
        BahamutSetting.chicagoServerHostPort = 0
        BahamutSetting.userId = nil
        ShareLinkSDK.sharedInstance.cancelToken(){
            message in
            
        }
        ShareLinkSDK.sharedInstance.closeClients()
    }
    
    private func setLogined(validateResult:ValidateResult)
    {
        BahamutSetting.token = validateResult.AppToken
        BahamutSetting.isUserLogined = true
        BahamutSetting.shareLinkApiServer = validateResult.APIServer
        BahamutSetting.fileApiServer = validateResult.FileAPIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        BahamutSetting.chicagoServerHost = chicagoStrs[0]
        BahamutSetting.chicagoServerHostPort = UInt16(chicagoStrs[1])!
        BahamutSetting.userId = validateResult.UserId
        ServiceContainer.instance.userLogin(validateResult.UserId)
    }

    func validateAccessToken(apiTokenServer:String, accountId:String, accessToken: String,callback:(loginSuccess:Bool,message:String)->Void,registCallback:((registApiServer:String!)->Void)! = nil)
    {
        BahamutSetting.lastLoginAccountId = accountId
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
    
    func registNewUser(registModel:RegistModel,newUser:Sharelinker,callback:(isSuc:Bool,msg:String,validateResult:ValidateResult!)->Void)
    {
        let req = RegistNewSharelinkUserRequest()
        req.nickName = newUser.nickName
        req.motto = newUser.motto
        req.accessToken = registModel.accessToken
        req.accountId = registModel.accountId
        req.apiServerUrl = registModel.registUserServer
        let client = ShareLinkSDK.sharedInstance.getRegistClient()
        client.execute(req) { (result:SLResult<ValidateResult>) -> Void in
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