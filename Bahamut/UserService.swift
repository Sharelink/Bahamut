//
//  UserService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/31.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreFoundation
import Alamofire
import EVReflection

class UserService: ServiceProtocol
{
    @objc static var ServiceName:String{return "user service"}
    @objc func initService()
    {
    }
    
    private(set) lazy var myUserId:String!={
        return NSUserDefaults.standardUserDefaults().valueForKey("userId") as? String
    }()
    private(set) var myLinkedUsers:[ShareLinkUser]!
    
    private func initLinkedUsers()
    {
        myLinkedUsers = getLinkedUsers()
    }
    
    func registNewUser(registModel:RegistModel,newUser:ShareLinkUser,callback:(isSuc:Bool,msg:String)->Void)
    {
        let req = RegistNewSharelinkUserRequest()
        req.nickName = newUser.nickName
        req.accessToken = registModel.accessToken
        req.accountId = registModel.accountId
        req.apiServerUrl = registModel.registUserServer
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ValidateResult>) -> Void in
            if result.isFailure
            {
                callback(isSuc:false,msg:"Regist Failed");
            }else if let validateResult = result.returnObject
            {
                if validateResult.isValidateResultDataComplete()
                {
                    ShareLinkSDK.sharedInstance.useValidateData(validateResult)
                    ServiceContainer.getService(AccountService).setLogined(validateResult.UserId, token: validateResult.AppToken, shareLinkApiServer: validateResult.APIServer, fileApiServer: validateResult.FileAPIServer)
                    callback(isSuc: true, msg: "regist success")
                }else
                {
                    callback(isSuc: false, msg: "Data Error")
                }
            }else
            {
                callback(isSuc:false,msg:"Regist Failed");
            }
        }
    }
    
    func getUsers(userIds:[String]) -> [ShareLinkUser]
    {
        //Read from cache
        return PersistentManager.sharedInstance.getModels(ShareLinkUser.self, idValues: userIds)
    }
    
    
    //TODO: rebuild this ungly code
    func getUsersDivideWithLatinLetter(users:[ShareLinkUser]) -> [(String,[ShareLinkUser])]
    {
        var result = [(String,[ShareLinkUser])]()
        var dict = [String:[ShareLinkUser]]()
        for index in 0...25
        {
            let letterInt = 65 + index
            let key = StringHelper.IntToLetterString(letterInt)
            let list = [ShareLinkUser]()
            dict.updateValue(list, forKey: key)
        }
        dict.updateValue([ShareLinkUser](), forKey: "#")
        
        for user in users
        {
            let userNoteName = user.noteName ?? user.nickName
            let nickName:CFMutableStringRef = CFStringCreateMutableCopy(nil, 0, userNoteName);
            CFStringTransform(nickName,nil, kCFStringTransformToLatin, false)
            CFStringTransform(nickName, nil, kCFStringTransformStripDiacritics, false)
            
            let stringName = nickName as String
            let n = stringName.startIndex.advancedBy(1)
            let prefix = stringName.uppercaseString.substringToIndex(n)
            var list = dict[prefix]
            if list == nil
            {
                list = dict["#"]
            }
            list?.append(user)
            dict.updateValue(list!, forKey: prefix) //if not update ,the list in the dict is point to old list ,not appended list
        }
        
        for item in dict
        {
            if item.1.count > 0
            {
                result.append((item.0,item.1))
            }
        }
        result.sortInPlace { (a, b) -> Bool in
            a.0 < b.0
        }
        return result
    }
    
    func getUser(userId:String, serverNewestCallback:((newestUser:ShareLinkUser!, msg:String!)->Void)! = nil) -> ShareLinkUser?
    {
        //Read from cache
        let user = PersistentManager.sharedInstance.getModel(ShareLinkUser.self, idValue: userId)
        
        //request server
        let req = GetShareLinkUsersRequest()
        req.userIds = [userId]
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req){ (result: SLResult<[ShareLinkUser]>) -> Void in
            var newestUser:ShareLinkUser!
            var msg:String! = nil
            if result.statusCode != ReturnCode.OK
            {
                newestUser = nil
                msg = result.originResult.description
            }else if let returnObject = result.returnObject
            {
                newestUser = returnObject.filter{$0.userId == userId}[0]
            }
            if let callback = serverNewestCallback
            {
                callback(newestUser: newestUser, msg: msg)
            }
        }

        return user
    }
    
    func refreshMyLinkedUsers(refreshCallback:(isSuc:Bool, msg:String!)->Void)
    {
        let req = GetUserLinksRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req) { (result:SLResult<[UserLink]>) -> Void in
            
            if result.statusCode == ReturnCode.OK
            {
                if let userLinks:[UserLink] = result.returnObject
                {
                    let userIds = userLinks.map{ user -> String in
                        return user.slaveUserId
                    }
                    let usersReq = GetShareLinkUsersRequest()
                    usersReq.userIds = userIds
                    ShareLinkSDK.sharedInstance.getShareLinkClient().execute(usersReq) { (result:SLResult<[ShareLinkUser]>) -> Void in
                        if result.statusCode == ReturnCode.OK
                        {
                            if let users:[ShareLinkUser] = result.returnObject
                            {
                                UserLink.saveObjectOfArray(userLinks)
                                ShareLinkUser.saveObjectOfArray(users)
                                PersistentManager.sharedInstance.refreshCache(UserLink)
                                PersistentManager.sharedInstance.refreshCache(ShareLinkUser)
                                self.initLinkedUsers()
                                refreshCallback(isSuc: true, msg: "")
                            }else{
                                refreshCallback(isSuc: false, msg: result.originResult.description)
                            }
                        }else{
                            refreshCallback(isSuc: false, msg: result.originResult.description)
                        }
                    }
                }else{
                    refreshCallback(isSuc: false, msg: result.originResult.description)
                }
            }else
            {
                refreshCallback(isSuc: false, msg: result.originResult.description)
            }
        }
    }
    
    private func getLinkedUsers() -> [ShareLinkUser]
    {
        let myLinkedUserLink = PersistentManager.sharedInstance.getAllModel(UserLink)
        let userIds = myLinkedUserLink.filter{$0.masterUserId == self.myUserId}.map{ link -> String in
            return link.slaveUserId
        }
        return getUsers(userIds)
    }
    
    func setProfileNick(newNick:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateShareLinkUserProfileNickNameRequest()
        req.nickName = newNick
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req){ (result:SLResult<ShareLinkObject>) -> Void in
            var isSuc:Bool = false
            var msg:String! = nil
            if result.statusCode == ReturnCode.OK
            {
                isSuc = true
            }else
            {
                msg = result.originResult.description
            }
            if let callback = setProfileCallback
            {
                callback(isSuc: isSuc, msg: msg)
            }
        }
    }
    
    func setProfileSignText(newSignText:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateShareLinkUserProfileSignTextRequest()
        req.signText = newSignText
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req){ (result:SLResult<ShareLinkObject>) -> Void in
            var isSuc:Bool = false
            var msg:String! = nil
            if result.statusCode == ReturnCode.OK
            {
                isSuc = true
            }else
            {
                msg = result.originResult.description
            }
            if let callback = setProfileCallback
            {
                callback(isSuc: isSuc, msg: msg)
            }
        }
    }
    
    
}