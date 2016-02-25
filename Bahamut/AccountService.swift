//
//  AccountService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class RegistModel {
    var registUserServer:String!
    var accountId:String!
    var accessToken:String!
    var userName:String!
    var region:String!
}

class AccountService: ServiceProtocol
{
    @objc static var ServiceName:String{return "Account Service"}
    
    @objc func userLoginInit(userId:String)
    {
        SharelinkSDK.sharedInstance.reuse(UserSetting.userId, token: UserSetting.token, shareLinkApiServer: SharelinkSetting.shareLinkApiServer, fileApiServer: SharelinkSetting.fileApiServer)
        SharelinkSDK.setAppVersion(SharelinkVersion)
        SharelinkSDK.sharedInstance.startClients()
        ChicagoClient.sharedInstance.start()
        ChicagoClient.sharedInstance.connect(SharelinkSetting.chicagoServerHost, port: SharelinkSetting.chicagoServerHostPort)
        ChicagoClient.sharedInstance.startHeartBeat()
        ChicagoClient.sharedInstance.useValidationInfo(userId, appkey: SharelinkSDK.appkey, apptoken: UserSetting.token)
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        MobClick.profileSignOff()
        ChicagoClient.sharedInstance.logout()
        UserSetting.token = nil
        UserSetting.isUserLogined = false
        SharelinkSetting.fileApiServer = nil
        SharelinkSetting.shareLinkApiServer = nil
        SharelinkSetting.chicagoServerHost = nil
        SharelinkSetting.chicagoServerHostPort = 0
        UserSetting.userId = nil
        SharelinkSDK.sharedInstance.cancelToken(){
            message in
            
        }
        SharelinkSDK.sharedInstance.closeClients()
    }
    
    private func setLogined(validateResult:ValidateResult)
    {
        UserSetting.token = validateResult.AppToken
        UserSetting.isUserLogined = true
        SharelinkSetting.shareLinkApiServer = validateResult.APIServer
        SharelinkSetting.fileApiServer = validateResult.FileAPIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        SharelinkSetting.chicagoServerHost = chicagoStrs[0]
        SharelinkSetting.chicagoServerHostPort = UInt16(chicagoStrs[1])!
        UserSetting.userId = validateResult.UserId
        ServiceContainer.instance.userLogin(validateResult.UserId)
    }

    func validateAccessToken(apiTokenServer:String, accountId:String, accessToken: String,callback:(loginSuccess:Bool,message:String)->Void,registCallback:((registApiServer:String!)->Void)! = nil)
    {
        UserSetting.lastLoginAccountId = accountId
        SharelinkSDK.sharedInstance.validateAccessToken(apiTokenServer, accountId: accountId, accessToken: accessToken) { (isNewUser, error, registApiServer,validateResult) -> Void in
            if isNewUser
            {
                registCallback(registApiServer:registApiServer)
            }else if error == nil{
                self.setLogined(validateResult)
                callback(loginSuccess: true, message: "")
                MobClick.profileSignInWithPUID(validateResult.UserId)
            }else{
                callback(loginSuccess: false, message: "VALIDATE_ACCTOKEN_FAILED".localizedString())
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
        let client = SharelinkSDK.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<ValidateResult>) -> Void in
            if result.isFailure
            {
                callback(isSuc:false,msg: "REGIST_FAILED".localizedString(),validateResult: nil);
            }else if let validateResult = result.returnObject
            {
                if validateResult.isValidateResultDataComplete()
                {
                    SharelinkSDK.sharedInstance.useValidateData(validateResult)
                    self.setLogined(validateResult)
                    callback(isSuc: true, msg: "REGIST_SUC".localizedString(),validateResult:validateResult)
                }else
                {
                    callback(isSuc: false, msg:"DATA_ERROR".localizedString(),validateResult:nil)
                }
            }else
            {
                callback(isSuc:false,msg:"REGIST_FAILED".localizedString(),validateResult:nil);
            }
        }
    }
    
    func changePassword(oldPsw:String,newPsw:String,callback:(isSuc:Bool)->Void)
    {
        let req = ChangeAccountPasswordRequest()
        req.oldPassword = oldPsw.sha256
        req.newPassword = newPsw.sha256
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result) -> Void in
            if result.isSuccess && String.isNullOrWhiteSpace(result.value) == false && result.value!.lowercaseString == "true"
            {
                callback(isSuc: true)
            }else
            {
                callback(isSuc: false)
            }
        }
    }
}