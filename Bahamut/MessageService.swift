
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
        let req = GetNewShareMessagesRequest()
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
    
    func saveNewMessage(msgId:String,chatId:String,type:MessageType,time:NSDate,senderId:String,msgText:String?,data:NSData?) -> MessageEntity!
    {
        let msgEntity = PersistentManager.sharedInstance.getNewMessage(msgId)
        msgEntity.chatId = chatId
        msgEntity.type = type.rawValue
        msgEntity.time = time
        msgEntity.senderId = senderId
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
        let req = SendShareMessageRequest()
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
        var msgEntities = [MessageEntity]()
        for msg in msgs
        {
            let me = saveNewMessage(msg.msgId, chatId: msg.chatId, type: MessageType(rawValue: msg.msgType)!, time: msg.timeOfDate, senderId: msg.senderId, msgText: msg.msg, data: msg.msgData)
            msgEntities.append(me)
        }
        self.postNotificationName(MessageService.messageServiceNewMessageReceived, object: self, userInfo: [MessageServiceNewMessageEntities:msgEntities])
    }
    
    func getShareChatHub(shareId:String,shareSenderId:String) -> ShareChatHub
    {
        let uService = ServiceContainer.getService(UserService)
        var shareChats = PersistentManager.sharedInstance.getShareChats(shareId)
        if shareChats.count == 0
        {
            let chatId = getChatIdWithAudienceOfShareId(shareId, audienceId: shareSenderId)
            let newSCE = PersistentManager.sharedInstance.saveNewChat(shareId,chatId: chatId)
            newSCE.addUser(uService.myUserId)
            newSCE.saveModified()
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
    
    func getShareIdNotReadMessageCount(shareId:String) -> UInt32
    {
        return 23
    }
}