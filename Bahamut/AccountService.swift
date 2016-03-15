//
//  AccountService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class RegistSharelinkModel {
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
        BahamutRFKit.sharedInstance.resetUser(userId,token:UserSetting.token)
        BahamutRFKit.sharedInstance.reuseApiServer(userId, token:UserSetting.token,appApiServer:SharelinkSetting.shareLinkApiServer)
        BahamutRFKit.sharedInstance.reuseFileApiServer(userId, token:UserSetting.token,fileApiServer:SharelinkSetting.fileApiServer)
        BahamutRFKit.sharedInstance.startClients()
        ChicagoClient.sharedInstance.start()
        ChicagoClient.sharedInstance.connect(SharelinkSetting.chicagoServerHost, port: SharelinkSetting.chicagoServerHostPort)
        ChicagoClient.sharedInstance.startHeartBeat()
        ChicagoClient.sharedInstance.useValidationInfo(userId, appkey: BahamutRFKit.appkey, apptoken: UserSetting.token)
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
        BahamutRFKit.sharedInstance.cancelToken(){
            message in
            
        }
        BahamutRFKit.sharedInstance.closeClients()
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
        BahamutRFKit.sharedInstance.validateAccessToken("\(apiTokenServer)/Tokens", accountId: accountId, accessToken: accessToken) { (isNewUser, error,validateResult) -> Void in
            if isNewUser
            {
                registCallback(registApiServer:validateResult.RegistAPIServer)
            }else if error == nil{
                self.setLogined(validateResult)
                callback(loginSuccess: true, message: "")
                MobClick.profileSignInWithPUID(validateResult.UserId)
            }else{
                callback(loginSuccess: false, message: "VALIDATE_ACCTOKEN_FAILED".localizedString())
            }
            
        }
    }
    
    func registNewUser(registModel:RegistSharelinkModel,newUser:Sharelinker,callback:(isSuc:Bool,msg:String,validateResult:ValidateResult!)->Void)
    {
        let req = RegistNewSharelinkUserRequest()
        req.nickName = newUser.nickName
        req.motto = newUser.motto
        req.accessToken = registModel.accessToken
        req.accountId = registModel.accountId
        req.apiServerUrl = registModel.registUserServer
        req.region = registModel.region
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<ValidateResult>) -> Void in
            if result.isFailure
            {
                callback(isSuc:false,msg: "REGIST_FAILED".localizedString(),validateResult: nil);
            }else if let validateResult = result.returnObject
            {
                if validateResult.isValidateResultDataComplete()
                {
                    BahamutRFKit.sharedInstance.useValidateData(validateResult)
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
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
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