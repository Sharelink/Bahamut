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

//MARK: service define
let UserServiceFirstLinkMessage = "UserServiceFirstLinkMessage"
let UserServiceNewLinkMessageCount = "UserServiceNewLinkMessageCount"

class UserService: NSNotificationCenter,ServiceProtocol
{
    static let userListUpdated = "userListUpdated"
    static let linkMessageUpdated = "linkMessageUpdated"
    static let myUserInfoRefreshed = "myUserInfoRefreshed"
    static let newLinkMessageUpdated = "newLinkMessageUpdated"
    
    @objc static var ServiceName:String{return "user service"}
    
    @objc func appStartInit()
    {
        
    }
    
    var myUserId:String{
        return BahamutConfig.userId
    }
    
    @objc func userLoginInit(userId:String)
    {
        initLinkedUsers()
        myUserModel = self.getUser(BahamutConfig.userId, serverNewestCallback: { (newestUser, msg) -> Void in
            self.myUserModel = newestUser
            self.postNotificationName(UserService.myUserInfoRefreshed, object: self)
        })
        if myUserModel != nil
        {
            self.postNotificationName(UserService.myUserInfoRefreshed, object: self)
        }
        let linkMessageRoute = ChicagoRoute()
        linkMessageRoute.CmdName = "UsrNewLinkMsg"
        linkMessageRoute.ExtName = "NotificationCenter"
        ChicagoClient.sharedInstance.addChicagoObserver(linkMessageRoute, observer: self, selector: "onNewLinkMessage:")
        self.refreshMyLinkedUsers()
    }
    
    func userLogout(userId: String) {
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    private(set) var myUserModel:ShareLinkUser!
    
    private(set) var askingLinkUserList:[LinkMessage]!
    private(set) var linkMessageList:[LinkMessage]!
    
    private(set) var myLinkedUsers:[ShareLinkUser] = [ShareLinkUser]()
    private(set) var myLinkedUsersMap:[String:ShareLinkUser] = [String:ShareLinkUser]()
    
    private func initLinkedUsers()
    {
        let users = getLinkedUsers()
        myLinkedUsersMap.removeAll()
        for u in users
        {
            myLinkedUsersMap.updateValue(u, forKey: u.userId)
        }
        myLinkedUsers = myLinkedUsersMap.map{$0.1}
    }
    
    //MARK: get datas
    
    func getUserNoteName(userId:String) -> String
    {
        let user = getUser(userId)
        return user?.noteName ?? user?.nickName ?? ""
    }
    
    func getUserNickName(userId:String) -> String!
    {
        return getUser(userId)?.nickName
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
        var user:ShareLinkUser! = nil
        if let u = myLinkedUsersMap[userId]
        {
            user = u
        }else if let u = PersistentManager.sharedInstance.getModel(ShareLinkUser.self, idValue: userId)
        {
            myLinkedUsersMap[userId] = u
            user = u
        }
        if serverNewestCallback == nil
        {
            return user
        }
        
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
                newestUser.saveModel()
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
                                self.postNotificationName(UserService.linkMessageUpdated, object: self)
                          
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
    
    //MARK: add link and remove link
    
    func onNewLinkMessage(a:NSNotification)
    {
        getNewLinkMessageFromServer()
    }
    
    func getNewLinkMessageFromServer()
    {
        let req = GetLinkMessagesRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<[LinkMessage]>) -> Void in
            if result.isSuccess && result.returnObject != nil && result.returnObject.count > 0
            {
                LinkMessage.saveObjectOfArray(result.returnObject)
                
                var linkMsgs = PersistentManager.sharedInstance.getAllModelFromCache(LinkMessage)
                linkMsgs.sortInPlace({ (a, b) -> Bool in
                    a.time.dateTimeOfString.compare(b.time.dateTimeOfString) == .OrderedAscending
                })
                self.askingLinkUserList = linkMsgs.filter{ $0.type == LinkMessageType.AskLink.rawValue }
                self.linkMessageList = linkMsgs.filter{$0.type == LinkMessageType.AcceptAskLink.rawValue }
                let dreq = DeleteLinkMessagesRequest()
                client.execute(dreq, callback: { (result:SLResult<ShareLinkObject>) -> Void in
                    
                })
                self.postNotificationName(UserService.linkMessageUpdated, object: self,userInfo: [UserServiceFirstLinkMessage:result.returnObject.first!])
                self.postNotificationName(UserService.newLinkMessageUpdated, object: self,userInfo: [UserServiceNewLinkMessageCount:result.returnObject.count])
                
                if (result.returnObject.filter{ $0.type == LinkMessageType.AcceptAskLink.rawValue}).count > 0
                {
                    self.refreshMyLinkedUsers()
                }
            }
        }
    }
    
    
    func generateSharelinkerQrString() -> String
    {
        return "sharelinker://userId=\(BahamutConfig.userId)"
    }
    
    func getSharelinkerIdFromQRString(qr:String)-> String
    {
        return qr.substringFromIndex("sharelinker://userId=".endIndex)
    }
    
    func deleteLinkMessage(id:String)
    {
        let linkMsg = LinkMessage()
        linkMsg.id = id
        self.linkMessageList.removeElement{ $0.id == id }
        PersistentManager.sharedInstance.removeModels([linkMsg])
        self.postNotificationName(UserService.linkMessageUpdated, object: self)
    }
    
    func acceptUserLink(userId:String,noteName:String!,callback:((isSuc:Bool) -> Void)! = nil)
    {
        let req = AcceptAskingLinkRequest()
        req.sharelinkerId = userId
        req.noteName = noteName
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<AULReturn>) -> Void in
            var suc = false
            if result.isSuccess{
                if let rs = result.returnObject
                {
                    rs.newLink.saveModel()
                    rs.newUser.saveModel()
                    PersistentManager.sharedInstance.refreshCache(UserLink)
                    PersistentManager.sharedInstance.refreshCache(ShareLinkUser)
                    suc = true
                    self.initLinkedUsers()
                    self.postNotificationName(UserService.userListUpdated, object: self)
                }
                
            }
            if let handler = callback
            {
                handler(isSuc: suc)
            }
        }
    }
    
    func askSharelinkForLink(sharelinkerId:String,callback:(isSuc:Bool)->Void)
    {
        let req = AddUserLinkRequest()
        req.otherUserId = sharelinkerId
        req.message = "\(myUserModel.nickName) want to add a link with you"
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ShareLinkObject>) -> Void in
            callback(isSuc: result.isSuccess)
        }
        
    }
    
    //MARK: set user profile
    
    func setMyAvatar(newAvatarId:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateAvatarRequest()
        req.newAvatarId = newAvatarId
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
            self.postNotificationName(UserService.myUserInfoRefreshed, object: self)
        }
    }
    
    func setMyProfileVideo(newVideoId:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
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
            self.postNotificationName(UserService.myUserInfoRefreshed, object: self)
        }
    }
    
    func setLinkerNoteName(userId:String,newNoteName:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
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
    
    func setProfileMotto(newMotto:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateShareLinkUserProfileMottoRequest()
        req.motto = newMotto
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