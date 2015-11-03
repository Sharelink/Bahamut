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
import SharelinkSDK

//
extension Sharelinker
{
    func getNoteName() -> String
    {
        if self.userId == BahamutSetting.userId
        {
            return NSLocalizedString("ME", comment: "")
        }
        return self.noteName ?? self.nickName ?? "Sharelinker"
    }
}

//MARK: service define
let UserServiceNewLinkMessage = "UserServiceNewLinkMessage"
let AskForLinkSharelinkerId = "AskForLinkSharelinkerId"

//MARK: UserService
class UserService: NSNotificationCenter,ServiceProtocol
{
    static let userListUpdated = "userListUpdated"
    static let linkMessageUpdated = "linkMessageUpdated"
    static let myUserInfoRefreshed = "myUserInfoRefreshed"
    static let newLinkMessageUpdated = "newLinkMessageUpdated"
    static var lastRefreshLinkedUserTime:NSDate!
    @objc static var ServiceName:String{return "user service"}
    
    var myUserId:String{
        return BahamutSetting.userId
    }
    
    @objc func userLoginInit(userId:String)
    {
        initLinkedUsers()
        myUserModel = self.getUser(BahamutSetting.userId, serverNewestCallback: { (newestUser, msg) -> Void in
            if newestUser != nil
            {
                self.myUserModel = newestUser
                self.postNotificationName(UserService.myUserInfoRefreshed, object: self)
            }
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
        self.refreshLinkMessage()
    }
    
    func userLogout(userId: String) {
        ShareSDK.cancelAuthWithType(ShareTypeFacebook)
        SharelinkCmdManager.sharedInstance.clearHandler()
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    private(set) var myUserModel:Sharelinker!
    private(set) var linkMessageList:[LinkMessage]!
    
    private(set) var myLinkedUsers:[Sharelinker] = [Sharelinker]()
    private(set) var myLinkedUsersMap:[String:Sharelinker] = [String:Sharelinker]()
    
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
    
    func isSharelinkerLinked(sharelinkerId:String) -> Bool
    {
        return myLinkedUsersMap.keys.contains(sharelinkerId)
    }
    
    func getUserNoteName(userId:String) -> String
    {
        let user = getUser(userId)
        return user?.getNoteName() ?? "Sharelinker"
    }
    
    func getUserNickName(userId:String) -> String
    {
        return getUser(userId)?.nickName ?? "Sharelinker"
    }
    
    func getUsers(userIds:[String]) -> [Sharelinker]
    {
        //Read from cache
        return PersistentManager.sharedInstance.getModels(Sharelinker.self, idValues: userIds)
    }
    
    func getUsersDivideWithLatinLetter(users:[Sharelinker]) -> [(latinLetter:String,items:[Sharelinker])]
    {
        var result = ArrayUtil.groupWithLatinLetter(users){$0.noteName ?? $0.nickName}
        result = result.filter{ $0.items.count > 0}
        return result
    }
    
    func getUser(userId:String, serverNewestCallback:((newestUser:Sharelinker!, msg:String!)->Void)! = nil) -> Sharelinker?
    {
        
        //Read from cache
        var user:Sharelinker! = nil
        if let u = myLinkedUsersMap[userId]
        {
            user = u
        }else if let u = PersistentManager.sharedInstance.getModel(Sharelinker.self, idValue: userId)
        {
            myLinkedUsersMap[userId] = u
            user = u
        }
        if serverNewestCallback == nil
        {
            return user
        }
        
        //request server
        let req = GetSharelinkersRequest()
        req.userIds = [userId]
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req){ (result: SLResult<[Sharelinker]>) -> Void in
            var newestUser:Sharelinker!
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
        let client = SharelinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req) { (result:SLResult<[UserLink]>) -> Void in
            
            if result.statusCode == ReturnCode.OK
            {
                if let userLinks:[UserLink] = result.returnObject
                {
                    let usersReq = GetSharelinkersRequest()
                    client.execute(usersReq) { (result:SLResult<[Sharelinker]>) -> Void in
                        if result.statusCode == ReturnCode.OK
                        {
                            if let users:[Sharelinker] = result.returnObject
                            {
                                UserLink.saveObjectOfArray(userLinks)
                                Sharelinker.saveObjectOfArray(users)
                                PersistentManager.sharedInstance.refreshCache(UserLink)
                                PersistentManager.sharedInstance.refreshCache(Sharelinker)
                                self.initLinkedUsers()
                                self.postNotificationName(UserService.userListUpdated, object: self)
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
    
    private func getLinkedUsers() -> [Sharelinker]
    {
        let myLinkedUserLink = PersistentManager.sharedInstance.getAllModelFromCache(UserLink)
        let userIds = myLinkedUserLink.map{ link -> String in
            return link.slaveUserId
        }
        return getUsers(userIds)
    }
    
    //MARK: add link and remove link
    
    func refreshLinkMessage()
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            var linkMsgs = PersistentManager.sharedInstance.getAllModelFromCache(LinkMessage)
            linkMsgs.sortInPlace({ (a, b) -> Bool in
                a.time.dateTimeOfString.compare(b.time.dateTimeOfString) == .OrderedAscending
            })
            self.linkMessageList = linkMsgs
            self.postNotificationName(UserService.linkMessageUpdated, object: self,userInfo: nil)
        }
    }
    
    func onNewLinkMessage(a:NSNotification)
    {
        getNewLinkMessageFromServer()
    }
    
    func getNewLinkMessageFromServer()
    {
        let req = GetLinkMessagesRequest()
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<[LinkMessage]>) -> Void in
            if let msgs = result.returnObject
            {
                if msgs.count == 0
                {
                    return
                }
                LinkMessage.saveObjectOfArray(msgs)
                PersistentManager.sharedInstance.refreshCache(LinkMessage)
                self.refreshLinkMessage()
                let msgsCopy = msgs.filter{$0 != nil}
                let uInfo = [UserServiceNewLinkMessage:msgsCopy]
                self.postNotificationName(UserService.newLinkMessageUpdated, object: self,userInfo: uInfo)
                self.notifyServerLinkMessageReceived()
                if (msgs.contains{$0.isAcceptAskLinkMessage()})
                {
                    self.refreshMyLinkedUsers()
                }
            }
        }
    }

    private func notifyServerLinkMessageReceived()
    {
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        let dreq = DeleteLinkMessagesRequest()
        client.execute(dreq, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            
        })
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
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<AULReturn>) -> Void in
            var suc = false
            if let _ = result.returnObject
            {
                suc = true
                self.refreshMyLinkedUsers()
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
        req.message = String(format: NSLocalizedString("ASK_LINK_MSG",comment:""), myUserModel.nickName!)
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<ShareLinkObject>) -> Void in
            callback(isSuc: result.isSuccess)
        }
        
    }
    
    func generateSharelinkLinkMeCmd() -> String
    {
        let expriedAt = NSDate(timeIntervalSinceNow: 7 * 24 * 3600)
        return SharelinkCmd.generateSharelinkCmdEncoded("linkMe", args: BahamutSetting.userId,self.myUserModel.nickName,expriedAt.toDateTimeString())
    }
    
    func generateSharelinkerQrString() -> String
    {
        return SharelinkCmd.buildSharelinkCmdUrl(generateSharelinkLinkMeCmd())
    }
    
    //MARK: set user profile
    
    func setMyAvatar(newAvatarId:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateAvatarRequest()
        req.newAvatarId = newAvatarId
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
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
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
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
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
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
        let req = UpdateSharelinkerProfileNickNameRequest()
        req.nickName = newNick
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
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
        let req = UpdateSharelinkerProfileMottoRequest()
        req.motto = newMotto
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
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