//
//  UserService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/31.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreFoundation

//special note name
let SharelinkerCenterNoteName = "#<SharelinkCenter>#"
extension Sharelinker
{
    func getNoteName() -> String
    {
        if self.userId == UserSetting.userId
        {
            return "ME".localizedString()
        }else if self.noteName == SharelinkerCenterNoteName
        {
            return SharelinkerCenterNoteName.localizedString()
        }
        return self.noteName ?? self.nickName ?? "Sharelinker"
    }
}

//MARK: service define
let UserServiceNewLinkMessage = "UserServiceNewLinkMessage"
let AskForLinkSharelinkerId = "AskForLinkSharelinkerId"
let linkMessageRoute:ChicagoRoute = {
    let linkMessageRoute = ChicagoRoute()
    linkMessageRoute.CmdName = "UsrNewLinkMsg"
    linkMessageRoute.ExtName = "NotificationCenter"
    return linkMessageRoute
}()

//MARK: validate linkmessage
extension LinkMessage
{
    func isInvalidData() -> Bool
    {
        return id == nil || sharelinkerId == nil || type == nil
    }
}

//MARK: UserService
class UserService: NSNotificationCenter,ServiceProtocol
{
    static let userListUpdated = "userListUpdated"
    static let linkMessageUpdated = "linkMessageUpdated"
    static let newLinkMessageUpdated = "newLinkMessageUpdated"
    static let myUserInfoRefreshed = "myUserInfoRefreshed"
    static let baseUserDataInited = "baseUserDataInited"
    static var lastRefreshLinkedUserTime:NSDate!
    @objc static var ServiceName:String{return "User Service"}
    
    var myUserId:String{
        return UserSetting.userId
    }
    
    @objc func userLoginInit(userId:String)
    {
        ChicagoClient.sharedInstance.addChicagoObserver(linkMessageRoute, observer: self, selector: "onNewLinkMessage:")
        self.initServiceBaseData()
    }
    
    func userLogout(userId: String) {
        #if APP_VERSION
        ShareSDK.cancelAuthWithType(ShareTypeFacebook)
        #endif
        BahamutCmdManager.sharedInstance.clearHandler()
        ChicagoClient.sharedInstance.removeObserver(self)
        myUserModel = nil
        linkMessageList.removeAll()
        myLinkedUsers.removeAll()
        myLinkedUsersMap.removeAll()
    }
    
    private(set) var myUserModel:Sharelinker!{
        didSet{
            if myUserModel != nil
            {
                self.postNotificationName(UserService.myUserInfoRefreshed, object: self)
            }
        }
    }
    private(set) var linkMessageList:[LinkMessage] = [LinkMessage]()
    
    private(set) var myLinkedUsers:[Sharelinker] = [Sharelinker]()
    private(set) var myLinkedUsersMap:[String:Sharelinker] = [String:Sharelinker]()
    
    private func initServiceBaseData()
    {
        myUserModel = self.getUser(UserSetting.userId, serverNewestCallback: { (newestUser, msg) -> Void in
            if newestUser != nil
            {
                self.myUserModel = newestUser
                self.refreshMyLinkedUsers()
                self.refreshLinkMessage()
            }else if self.myUserModel != nil
            {
                self.initLinkedUsers()
            }else{
                ServiceContainer.instance.postInitServiceFailed("INIT_USER_DATA_ERROR")
            }
        })
        if myUserModel != nil
        {
            self.initLinkedUsers()
        }
    }
    
    private func initLinkedUsers()
    {
        let users = getLinkedUsers()
        myLinkedUsersMap.removeAll()
        for u in users
        {
            myLinkedUsersMap.updateValue(u, forKey: u.userId)
        }
        myLinkedUsers = myLinkedUsersMap.map{$0.1}
        if myUserModel != nil && myLinkedUsers.count > 0
        {
            PersistentManager.sharedInstance.saveModelChanges()
            if self.isServiceReady == false
            {
                self.postNotificationName(UserService.baseUserDataInited, object: self)
                self.setServiceReady()
            }
        }
    }
    
    //MARK: get datas
    
    func isSharelinkerLinked(sharelinkerId:String) -> Bool
    {
        return myLinkedUsersMap.keys.contains(sharelinkerId)
    }
    
    func getUserNoteName(userId:String) -> String
    {
        let user = getUser(userId)
        return user?.getNoteName() ?? ""
    }
    
    func getUserNickName(userId:String) -> String
    {
        return getUser(userId)?.nickName ?? ""
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
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req){ (result: SLResult<[Sharelinker]>) -> Void in
            var newestUser:Sharelinker!
            var msg:String! = nil
            if result.isFailure
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
        let client = BahamutRFKit.sharedInstance.getBahamutClient() as! BahamutRFClient
        client.execute(req) { (result:SLResult<[UserLink]>) -> Void in
            
            if result.isSuccess
            {
                if let userLinks:[UserLink] = result.returnObject
                {
                    let usersReq = GetSharelinkersRequest()
                    client.execute(usersReq) { (result:SLResult<[Sharelinker]>) -> Void in
                        if result.isSuccess
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
            self.linkMessageList.removeAll()
            self.linkMessageList.appendContentsOf(linkMsgs)
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
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<[LinkMessage]>) -> Void in
            if var msgs = result.returnObject
            {
                msgs = msgs.filter{!$0.isInvalidData()} //AlamofireJsonToObject Issue:responseArray will invoke all completeHandler
                if msgs.count == 0
                {
                    return
                }
                
                LinkMessage.saveObjectOfArray(msgs)
                PersistentManager.sharedInstance.refreshCache(LinkMessage)
                PersistentManager.sharedInstance.saveAll()
                self.refreshLinkMessage()
                let msgsCopy = msgs.filter{$0 != nil}
                let uInfo = [UserServiceNewLinkMessage:msgsCopy]
                self.postNotificationName(UserService.newLinkMessageUpdated, object: self,userInfo: uInfo)
                self.clearServerLinkMessages()
                if (msgs.contains{$0.isAcceptAskLinkMessage()})
                {
                    self.refreshMyLinkedUsers()
                }
            }
        }
    }

    private func clearServerLinkMessages()
    {
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        let dreq = DeleteLinkMessagesRequest()
        client.execute(dreq, callback: { (result:SLResult<BahamutObject>) -> Void in
            
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
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<AULReturn>) -> Void in
            var suc = false
            if let _ = result.returnObject
            {
                suc = true
                let askingMsgs = self.linkMessageList.removeElement({ (msg) -> Bool in
                    return msg.isAskingLinkMessage() && msg.sharelinkerId == userId
                })
                PersistentManager.sharedInstance.removeModels(askingMsgs)
                let acceptLinkMsg = LinkMessage()
                acceptLinkMsg.type = LinkMessageType.NewLinkAccepted.rawValue
                acceptLinkMsg.message = "accepted"
                acceptLinkMsg.sharelinkerId = userId
                acceptLinkMsg.sharelinkerNick = noteName
                acceptLinkMsg.avatar = askingMsgs.count > 0 ? askingMsgs[0].avatar : nil
                acceptLinkMsg.time = NSDate().toLocalDateTimeString()
                acceptLinkMsg.id = IdUtil.generateUniqueId()
                acceptLinkMsg.saveModel()
                
                PersistentManager.sharedInstance.saveModelChanges()
                self.linkMessageList.insert(acceptLinkMsg, atIndex: 0)
                
                self.postNotificationName(UserService.linkMessageUpdated, object: nil)
                self.refreshMyLinkedUsers()
            }
            if let handler = callback
            {
                handler(isSuc: suc)
            }
        }
    }
    
    func askSharelinkForLink(sharelinkerId:String,askNick:String,callback:(isSuc:Bool)->Void)
    {
        let req = AddUserLinkRequest()
        req.otherUserId = sharelinkerId
        req.message = askNick
        MobClick.event("SendAskLinkRequest")
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<BahamutObject>) -> Void in
            callback(isSuc: result.isSuccess)
        }
        
    }
    
    func generateSharelinkLinkMeCmd() -> String
    {
        let expriedAt = NSDate(timeIntervalSinceNow: 7 * 24 * 3600)
        return BahamutCmd.generateBahamutCmdEncoded("linkMe", args: UserSetting.userId,self.myUserModel.nickName,expriedAt.toDateTimeString())
    }
    
    func generateSharelinkerQrString() -> String
    {
        return BahamutCmd.buildBahamutCmdUrl(generateSharelinkLinkMeCmd())
    }
    
    
    //MARK: set linker note
    func setLinkerNoteName(userId:String,newNoteName:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateLinkedUserNoteNameRequest()
        req.newNoteName = newNoteName
        req.userId = userId
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req){ (result:SLResult<BahamutObject>) -> Void in
            var isSuc:Bool = false
            var msg:String! = nil
            if result.isSuccess
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
    
    //MARK: set user profile
    
    func setMyAvatar(newAvatarId:String,setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateAvatarRequest()
        req.newAvatarId = newAvatarId
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req){ (result:SLResult<BahamutObject>) -> Void in
            var isSuc:Bool = false
            var msg:String! = nil
            if result.isSuccess
            {
                isSuc = true
                self.myUserModel.avatarId = newAvatarId
                self.myUserModel.saveModel()
                self.myLinkedUsers.filter{$0.userId == self.myUserId}.first?.avatarId = newAvatarId
                self.myLinkedUsersMap[self.myUserId]?.avatarId = newAvatarId
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
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req){ (result:SLResult<BahamutObject>) -> Void in
            var isSuc:Bool = false
            var msg:String! = nil
            if result.isSuccess
            {
                isSuc = true
                self.myUserModel.personalVideoId = newVideoId
                self.myUserModel.saveModel()
                self.myLinkedUsers.filter{$0.userId == self.myUserId}.first?.personalVideoId = newVideoId
                self.myLinkedUsersMap[self.myUserId]?.personalVideoId = newVideoId
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

    
    func setProfileNick(newNick:String,setProfileCallback:((isSuc:Bool)->Void)! = nil)
    {
        let req = UpdateSharelinkerProfileNickNameRequest()
        req.nickName = newNick
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req){ (result:SLResult<BahamutObject>) -> Void in
            var isSuc:Bool = false
            if result.isSuccess
            {
                isSuc = true
                self.myUserModel.nickName = newNick
                self.myUserModel.saveModel()
                self.myLinkedUsers.filter{$0.userId == self.myUserId}.first!.nickName = newNick
                self.myLinkedUsersMap[self.myUserId]?.nickName = newNick
            }
            if let callback = setProfileCallback
            {
                callback(isSuc: isSuc)
            }
        }
    }
    
    func setProfileMotto(newMotto:String,setProfileCallback:((isSuc:Bool)->Void)! = nil)
    {
        let req = UpdateSharelinkerProfileMottoRequest()
        req.motto = newMotto
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req){ (result:SLResult<BahamutObject>) -> Void in
            var isSuc:Bool = false
            if result.isSuccess
            {
                isSuc = true
                self.myUserModel.motto = newMotto
                self.myUserModel.saveModel()
                self.myLinkedUsers.filter{$0.userId == self.myUserId}.first!.motto = newMotto
                self.myLinkedUsersMap[self.myUserId]?.motto = newMotto
            }
            if let callback = setProfileCallback
            {
                callback(isSuc: isSuc)
            }
        }
    }
    
    
}