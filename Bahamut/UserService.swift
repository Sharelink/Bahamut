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

class UserService: NSNotificationCenter,ServiceProtocol
{
    static let userListUpdated = "userListUpdated"
    static let askingLinkUserListUpdated = "askingLinkUserListUpdated"
    
    @objc static var ServiceName:String{return "user service"}
    
    @objc func appStartInit()
    {
        
    }
    
    @objc func userLoginInit(userId:String)
    {
        myUserId = userId
        initLinkedUsers()
    }
    
    private(set) var myUserId:String!
    
    var myUserModel:ShareLinkUser{
        return getUser(myUserId)!
    }
    
    private(set) var askingLinkUserList:[ShareLinkUser]!
    private(set) var myLinkedUsers:[ShareLinkUser]!
    
    private func initLinkedUsers()
    {
        myLinkedUsers = getLinkedUsers()
    }
    
    func registNewUser(registModel:RegistModel,newUser:ShareLinkUser,callback:(isSuc:Bool,msg:String,validateResult:ValidateResult!)->Void)
    {
        let req = RegistNewSharelinkUserRequest()
        req.nickName = newUser.nickName
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
    
    func getUsers(userIds:[String]) -> [ShareLinkUser]
    {
        //Read from cache
        return PersistentManager.sharedInstance.getModels(ShareLinkUser.self, idValues: userIds)
    }
    
    func getUsersDivideWithLatinLetter(users:[ShareLinkUser]) -> [(latinLetter:String,items:[ShareLinkUser])]
    {
        var result = ArrayUtil.groupWithLatinLetter(users){$0.noteName ?? $0.nickName}
        result = result.filter{ $0.items.count > 0}
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
    
    func refreshMyLinkedUsers()
    {
        let req = GetUserLinksRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req) { (result:SLResult<[UserLink]>) -> Void in
            
            if result.statusCode == ReturnCode.OK
            {
                if let userLinks:[UserLink] = result.returnObject
                {
                    let usersReq = GetShareLinkUsersRequest()
                    client.execute(usersReq) { (result:SLResult<[ShareLinkUser]>) -> Void in
                        if result.statusCode == ReturnCode.OK
                        {
                            if let users:[ShareLinkUser] = result.returnObject
                            {
                                UserLink.saveObjectOfArray(userLinks)
                                ShareLinkUser.saveObjectOfArray(users)
                                PersistentManager.sharedInstance.refreshCache(UserLink)
                                PersistentManager.sharedInstance.refreshCache(ShareLinkUser)
                                self.initLinkedUsers()
                                self.postNotificationName(UserService.userListUpdated, object: self)
                                self.postNotificationName(UserService.askingLinkUserListUpdated, object: self)
                          
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getUserLink(userId:String) -> UserLink?
    {
        return PersistentManager.sharedInstance.getModel(UserLink.self, idValue: userId)
    }
    
    private func getLinkedUsers() -> [ShareLinkUser]
    {
        let myLinkedUserLink = PersistentManager.sharedInstance.getAllModelFromCache(UserLink)
        let userIds = myLinkedUserLink.map{ link -> String in
            return link.slaveUserId
        }
        return getUsers(userIds)
    }
    
    func rejectUserLink(userId:String!)
    {
        let req = UpdateUserLinkStatusWithOtherRequest()
        req.userId = userId
        req.status = UserLinkStatus.Rejected.rawValue.description
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ShareLinkObject>) -> Void in
            if result.isSuccess{
                self.refreshMyLinkedUsers()
            }
        }
    }
    
    func acceptUserLink(userId:String,noteName:String!,callback:((isSuc:Bool) -> Void)! = nil)
    {
        let req = UpdateUserLinkStatusWithOtherRequest()
        req.userId = userId
        req.status = UserLinkStatus.Linked.rawValue.description
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ShareLinkObject>) -> Void in
            if result.isSuccess{
                self.refreshMyLinkedUsers()
                self.setUserNoteName(userId, newNoteName: noteName)
            }
        }
    }
    
    func askSharelinkForLink(accountId:String,callback:(isSuc:Bool)->Void)
    {
        let req = AddUserLinkRequest()
        req.accountId = accountId
        req.note = "\(myUserModel.nickName) want to add a link with you"
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ShareLinkObject>) -> Void in
            callback(isSuc: result.isSuccess)
        }
        
    }
    
    func setUserHeadIcon(newIconId:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateHeadIconRequest()
        req.newHeadIconId = newIconId
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
    
    func setUserProfileVideo(newVideoId:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateProfileVideoRequest()
        req.newProfileVideoId = newVideoId
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
    
    func setUserNoteName(userId:String,newNoteName:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateLinkedUserNoteNameRequest()
        req.newNoteName = newNoteName
        req.userId = userId
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