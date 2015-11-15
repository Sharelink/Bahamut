//
//  AccountService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import SharelinkSDK

class AccountService: ServiceProtocol
{
    @objc static var ServiceName:String{return "account service"}
    
    @objc func userLoginInit(userId:String)
    {
        SharelinkSDK.sharedInstance.reuse(BahamutSetting.userId, token: BahamutSetting.token, shareLinkApiServer: BahamutSetting.shareLinkApiServer, fileApiServer: BahamutSetting.fileApiServer)
        SharelinkSDK.sharedInstance.startClients()
    }
    
    @objc func userLogout(userId: String) {
        MobClick.profileSignOff()
        BahamutSetting.token = nil
        BahamutSetting.isUserLogined = false
        BahamutSetting.fileApiServer = nil
        BahamutSetting.shareLinkApiServer = nil
        BahamutSetting.chicagoServerHost = nil
        BahamutSetting.chicagoServerHostPort = 0
        BahamutSetting.userId = nil
        SharelinkSDK.sharedInstance.cancelToken(){
            message in
            
        }
        SharelinkSDK.sharedInstance.closeClients()
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
        SharelinkSDK.sharedInstance.validateAccessToken(apiTokenServer, accountId: accountId, accessToken: accessToken) { (isNewUser, error, registApiServer,validateResult) -> Void in
            if isNewUser
            {
                registCallback(registApiServer:registApiServer)
            }else if error == nil{
                self.setLogined(validateResult)
                callback(loginSuccess: true, message: "")
                MobClick.profileSignInWithPUID(validateResult.UserId)
            }else{
                callback(loginSuccess: false, message: NSLocalizedString("VALIDATE_ACCTOKEN_FAILED", comment: "Validate Access Token Failed"))
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
        req.region = registModel.region
        let client = SharelinkSDK.sharedInstance.getRegistClient()
        client.execute(req) { (result:SLResult<ValidateResult>) -> Void in
            if result.isFailure
            {
                callback(isSuc:false,msg: NSLocalizedString("REGIST_FAILED", comment: "Regist Failed"),validateResult: nil);
            }else if let validateResult = result.returnObject
            {
                if validateResult.isValidateResultDataComplete()
                {
                    SharelinkSDK.sharedInstance.useValidateData(validateResult)
                    self.setLogined(validateResult)
                    callback(isSuc: true, msg: NSLocalizedString("REGIST_SUC", comment: "Regist Success"),validateResult:validateResult)
                }else
                {
                    callback(isSuc: false, msg:NSLocalizedString("DATA_ERROR", comment: "Data Error"),validateResult:nil)
                }
            }else
            {
                callback(isSuc:false,msg:NSLocalizedString("REGIST_FAILED", comment: ""),validateResult:nil);
            }
        }
    }
}