
//
//  ReplyService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import EVReflection

//Static entities
class ShareNewMessageRecord:ShareLinkObject
{
    var shareId:String!
    var newMessageCount:NSNumber!
    
    override func getObjectUniqueIdName() -> String {
        return "shareId"
    }
}

//MARK:MessageService

let MessageServiceNewMessageEntities = "MessageServiceNewMessageEntities"

class MessageService:NSNotificationCenter,ServiceProtocol
{
    static let messageServiceNewMessageReceived = "MessageServiceNewMessageReceived"
    
    @objc static var ServiceName:String {return "MessageService"}
    @objc func appStartInit() {}
    
    @objc func userLoginInit(userId: String)
    {
        let route = ChicagoRoute()
        route.ExtName = "NotificationCenter"
        route.CmdName = "UsrNewMsg"
        ChicagoClient.sharedInstance.start()
        ChicagoClient.sharedInstance.addChicagoObserver(route, observer: self, selector: "newMessage:")
        ChicagoClient.sharedInstance.connect(BahamutConfig.chicagoServerHost, port: BahamutConfig.chicagoServerHostPort)
        ChicagoClient.sharedInstance.startHeartBeat()
        ChicagoClient.sharedInstance.useValidationInfo(userId, appkey: ShareLinkSDK.appkey, apptoken: BahamutConfig.token)
    }
    
    func userLogout(userId: String) {
        ChicagoClient.sharedInstance.removeObserver(self)
        ChicagoClient.sharedInstance.close()
    }
    
    static let messageListUpdated = "messageListUpdated"
    
    func newMessage(a:NSNotification)
    {
        getMessageFromServer()
    }
    
    func getMessageFromServer()
    {
        let req = GetNewMessagesRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<[Message]>) -> Void in
            if result.isSuccess
            {
                if result.returnObject != nil && result.returnObject.count > 0
                {
                    self.recevieMessage(result.returnObject!)
                    let dreq = NotifyNewMessagesReceivedRequest()
                    client.execute(dreq, callback: { (result:SLResult<EVObject>) -> Void in
                        
                    })
                }
            }
        }
    }
    
    func getChatModel(chatId:String) -> ChatModel!
    {
        return getChatModelByEntity(PersistentManager.sharedInstance.getShareChat(chatId))
    }
    
    func getChatModelByEntity(entity:ShareChatEntity!) -> ChatModel!
    {
        if entity == nil{
            return nil
        }
        let uService = ServiceContainer.getService(UserService)
        let cm = ChatModel()
        cm.shareId = entity.shareId
        cm.chatId = entity.chatId
        cm.sharelinkers = entity.getUsers()
        if cm.sharelinkers.count == 1{
            let user = uService.getUser(cm.sharelinkers.first!)
            cm.chatTitle = user?.noteName
            cm.chatIcon = user?.avatarId
        }else{
            cm.chatTitle = "chat hub"
        }
        cm.audienceId = cm.sharelinkers.first
        cm.shareId = entity.shareId
        cm.chatEntity = entity
        return cm
    }
    
    func getChatIdWithAudienceOfShareId(shareId:String,audienceId:String) -> String
    {
        return "\(shareId)&\(audienceId)"
    }
    
    func getMessage(chatId:String,limit:Int = 7,beforeTime:NSDate! = nil) -> [MessageEntity]
    {
        return PersistentManager.sharedInstance.getMessage(chatId, limit: limit, beforeTime: beforeTime)
    }
    
    func saveNewMessage(msgId:String,chatId:String,shareId:String!,type:MessageType,time:NSDate,senderId:String,msgText:String?,data:NSData?) -> MessageEntity!
    {
        let msgEntity = PersistentManager.sharedInstance.getNewMessage(msgId)
        msgEntity.chatId = chatId
        msgEntity.type = type.rawValue
        msgEntity.time = time
        msgEntity.senderId = senderId
        msgEntity.shareId = shareId
        if type == .Text
        {
            msgEntity.msgText = msgText!
        }else if type == .Voice
        {
            msgEntity.msgData = data!
        }else if type == .Picture
        {
            msgEntity.msgData = data!
        }
        msgEntity.saveModified()
        return msgEntity
    }
    
    func sendMessage(chatId:String,msg:MessageEntity,shareId:String,audienceId:String)
    {
        let req = SendMessageRequest()
        req.time = msg.time
        req.type = msg.type
        req.chatId = chatId
        req.message = msg.msgText
        req.messageData = msg.msgData
        req.audienceId = audienceId
        req.shareId = shareId
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<Message>) -> Void in
            if result.isSuccess
            {
                msg.isSend = true
                msg.saveModified()
            }else
            {
                msg.sendFailed = NSNumber(bool: true)
            }
        }
    }
    
    private func recevieMessage(msgs:[Message])
    {
        let uService = ServiceContainer.getService(UserService)
        var msgEntities = [MessageEntity]()
        for msg in msgs
        {
            let me = saveNewMessage(msg.msgId, chatId: msg.chatId,shareId: msg.shareId, type: MessageType(rawValue: msg.msgType)!, time: msg.timeOfDate, senderId: msg.senderId, msgText: msg.msg, data: msg.msgData)
            if let ce = PersistentManager.sharedInstance.getShareChat(me.chatId)
            {
                ce.newMessage = ce.newMessage.integerValue + 1
            }else
            {
                let ce = createChatEntity(msg.chatId, audienceIds: [uService.myUserId,me.senderId], shareId: me.shareId)
                ce.newMessage = 1
                ce.saveModified()
            }
            msgEntities.append(me)
        }
        PersistentManager.sharedInstance.saveAll()
        self.postNotificationName(MessageService.messageServiceNewMessageReceived, object: self, userInfo: [MessageServiceNewMessageEntities:msgEntities])
    }
    
    func getShareChatHub(shareId:String,shareSenderId:String) -> ShareChatHub
    {
        let uService = ServiceContainer.getService(UserService)
        var shareChats = PersistentManager.sharedInstance.getShareChats(shareId)
        if shareChats.count == 0
        {
            let chatId = getChatIdWithAudienceOfShareId(shareId, audienceId: shareSenderId)
            var audienceIds = [uService.myUserId]
            if uService.myUserId != shareSenderId
            {
                audienceIds.append(shareSenderId)
            }
            let newSCE = createChatEntity(chatId, audienceIds: audienceIds, shareId: shareId)
            shareChats.append(newSCE)
        }
        let chatModels = shareChats.map{return self.getChatModel($0.chatId)}.filter{$0 != nil}
        let sc = ShareChatHub()
        for cm in chatModels
        {
            cm.audienceId = shareSenderId
            sc.addChatModel(cm)
        }
        return sc
    }
    
    private func createChatEntity(chatId:String,audienceIds:[String],shareId:String) -> ShareChatEntity
    {
        let newSCE = PersistentManager.sharedInstance.saveNewChat(shareId,chatId: chatId)
        for audience in audienceIds
        {
            newSCE.addUser(audience)
        }
        newSCE.saveModified()
        return newSCE
    }
    
    func getShareNewMessageCount(shareId:String) -> Int
    {
        let shareChats = PersistentManager.sharedInstance.getShareChats(shareId)
        var sum = 0
        for sc in shareChats
        {
            sum += sc.newMessage.integerValue
        }
        return sum
    }
}