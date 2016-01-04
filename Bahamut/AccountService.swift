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
        SharelinkSDK.sharedInstance.reuse(SharelinkSetting.userId, token: SharelinkSetting.token, shareLinkApiServer: SharelinkSetting.shareLinkApiServer, fileApiServer: SharelinkSetting.fileApiServer)
        SharelinkSDK.setAppVersion(BahamutConfig.sharelinkVersion)
        SharelinkSDK.sharedInstance.startClients()
        ChicagoClient.sharedInstance.start()
        ChicagoClient.sharedInstance.connect(SharelinkSetting.chicagoServerHost, port: SharelinkSetting.chicagoServerHostPort)
        ChicagoClient.sharedInstance.startHeartBeat()
        ChicagoClient.sharedInstance.useValidationInfo(userId, appkey: SharelinkSDK.appkey, apptoken: SharelinkSetting.token)
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        MobClick.profileSignOff()
        ChicagoClient.sharedInstance.logout()
        SharelinkSetting.token = nil
        SharelinkSetting.isUserLogined = false
        SharelinkSetting.fileApiServer = nil
        SharelinkSetting.shareLinkApiServer = nil
        SharelinkSetting.chicagoServerHost = nil
        SharelinkSetting.chicagoServerHostPort = 0
        SharelinkSetting.userId = nil
        SharelinkSDK.sharedInstance.cancelToken(){
            message in
            
        }
        SharelinkSDK.sharedInstance.closeClients()
    }
    
    private func setLogined(validateResult:ValidateResult)
    {
        SharelinkSetting.token = validateResult.AppToken
        SharelinkSetting.isUserLogined = true
        SharelinkSetting.shareLinkApiServer = validateResult.APIServer
        SharelinkSetting.fileApiServer = validateResult.FileAPIServer
        let chicagoStrs = validateResult.ChicagoServer.split(":")
        SharelinkSetting.chicagoServerHost = chicagoStrs[0]
        SharelinkSetting.chicagoServerHostPort = UInt16(chicagoStrs[1])!
        SharelinkSetting.userId = validateResult.UserId
        ServiceContainer.instance.userLogin(validateResult.UserId)
    }

    func validateAccessToken(apiTokenServer:String, accountId:String, accessToken: String,callback:(loginSuccess:Bool,message:String)->Void,registCallback:((registApiServer:String!)->Void)! = nil)
    {
        SharelinkSetting.lastLoginAccountId = accountId
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
        let client = SharelinkSDK.sharedInstance.getBahamutClient()
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