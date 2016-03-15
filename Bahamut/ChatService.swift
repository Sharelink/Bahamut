
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

//MARK:ChatService

let ChatServiceNewMessageEntities = "ChatServiceNewMessageEntities"
let NewCreatedChatModels = "NewCreatedChatModels"
let NewChatModelsCreated = "NewChatModelsCreated"

extension Message
{
    func isInvalidData() -> Bool
    {
        return msgId == nil || shareId == nil || senderId == nil || msgType == nil || chatId == nil || msg == nil || time == nil
    }
}

class ChatService:NSNotificationCenter,ServiceProtocol
{
    static let messageServiceNewMessageReceived = "ChatServiceNewMessageReceived"
    private(set) var chattingShareId:String!
    private var chatMessageServerUrl:String!
    @objc static var ServiceName:String {return "Chat Service"}
    @objc func appStartInit(appName:String) {}
    
    @objc func userLoginInit(userId: String)
    {
        self.chatMessageServerUrl = BahamutRFKit.sharedInstance.appApiServer
        let route = ChicagoRoute()
        route.ExtName = "NotificationCenter"
        route.CmdName = "UsrNewMsg"
        ChicagoClient.sharedInstance.addChicagoObserver(route, observer: self, selector: "newMessage:")
        
        let chatServerChangedRoute = ChicagoRoute()
        chatServerChangedRoute.ExtName = "NotificationCenter"
        route.CmdName = "ChatServerChanged"
        ChicagoClient.sharedInstance.addChicagoObserver(chatServerChangedRoute, observer: self, selector: "chatServerChanged:")
        
        self.setServiceReady()
        self.getMessageFromServer()
    }
    
    func userLogout(userId: String) {
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    static let messageListUpdated = "messageListUpdated"
    
    func setChatAtShare(shareId:String)
    {
        self.chattingShareId = shareId
    }
    
    func isChatingAtShare(shareId:String) -> Bool
    {
        if String.isNullOrEmpty(shareId)
        {
            return false
        }
        return shareId == self.chattingShareId
    }
    
    func leaveChatRoom()
    {
        self.chattingShareId = nil
    }
    
    func chatServerChanged(a:NSNotification)
    {
        class ReturnValue:EVObject
        {
            var chatServerUrl:String!
        }
        
        if let userInfo = a.userInfo
        {
            if let json = userInfo[ChicagoClientReturnJsonValue] as? String
            {
                let value = ReturnValue(json: json)
                if let chatUrl = value.chatServerUrl
                {
                    if String.isNullOrWhiteSpace(chatUrl)
                    {
                        self.chatMessageServerUrl = chatUrl
                    }
                }
            }
            
        }
    }
    
    func newMessage(a:NSNotification)
    {
        getMessageFromServer()
    }
    
    func getMessageFromServer()
    {
        let req = GetNewMessagesRequest()
        req.apiServerUrl = self.chatMessageServerUrl
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<[Message]>) -> Void in
            if var msgs = result.returnObject
            {
                msgs = msgs.filter{!$0.isInvalidData()} //isInvalidData():AlamofireJsonToObject Issue:responseArray will invoke all completeHandler
                if msgs.count == 0
                {
                    return
                }
                
                self.recevieMessage(msgs)
                let dreq = NotifyNewMessagesReceivedRequest()
                dreq.apiServerUrl = self.chatMessageServerUrl
                client.execute(dreq, callback: { (result:SLResult<EVObject>) -> Void in
                    
                })
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
        if cm.sharelinkers.count >= 1{
            let user = uService.getUser(cm.sharelinkers.last!)
            cm.chatTitle = user?.getNoteName()
            cm.chatIcon = user?.avatarId
            cm.audienceId = user?.userId
        }else{
            cm.chatTitle = "chat hub"
        }
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
            msgEntity.msgText = msgText ?? ""
        }else if type == .Voice
        {
            msgEntity.msgData = data ?? NSData()
            msgEntity.msgText = msgText ?? "0"
        }else if type == .Picture
        {
            msgEntity.msgData = data ?? NSData()
        }
        PersistentManager.sharedInstance.saveMessageChanges()
        return msgEntity
    }
    
    func sendMessage(chatId:String,msg:MessageEntity,shareId:String,audienceId:String)
    {
        let req = SendMessageRequest()
        req.apiServerUrl = self.chatMessageServerUrl
        req.time = msg.time
        req.type = msg.type
        req.chatId = chatId
        req.message = msg.msgText
        req.messageData = msg.msgData
        req.audienceId = audienceId
        req.shareId = shareId
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<Message>) -> Void in
            if result.isSuccess
            {
                msg.isSend = true
                PersistentManager.sharedInstance.saveMessageChanges()
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
        var newChatModels = [ChatModel]()
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
                PersistentManager.sharedInstance.saveMessageChanges()
                let model = getChatModelByEntity(ce)
                newChatModels.append(model)
            }
            msgEntities.append(me)
        }
        PersistentManager.sharedInstance.saveMessageChanges()
        self.postNotificationName(ChatService.messageServiceNewMessageReceived, object: self, userInfo: [ChatServiceNewMessageEntities:msgEntities])
        if newChatModels.count > 0
        {
            self.postNotificationName(NewChatModelsCreated, object: self, userInfo: [NewCreatedChatModels:newChatModels])
        }
    }
    
    func getShareChatHub(shareId:String,shareSenderId:String) -> ShareChatHub
    {
        let uService = ServiceContainer.getService(UserService)
        var shareChats = PersistentManager.sharedInstance.getShareChats(shareId)
        if shareChats.count == 0
        {
            let chatId = getChatIdWithAudienceOfShareId(shareId, audienceId: uService.myUserId)
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
            sc.addChatModel(cm)
        }
        sc.shareId = shareId
        return sc
    }
    
    private func createChatEntity(chatId:String,audienceIds:[String],shareId:String) -> ShareChatEntity
    {
        let newSCE = PersistentManager.sharedInstance.saveNewChat(shareId,chatId: chatId)
        for audience in audienceIds
        {
            newSCE.addUser(audience)
        }
        PersistentManager.sharedInstance.saveMessageChanges()
        return newSCE
    }
    
    func getShareNewMessageCount(shareId:String) -> Int
    {
        let shareChats = PersistentManager.sharedInstance.getShareChats(shareId)
        var sum = 0
        for sc in shareChats
        {
            sum = sum + sc.newMessage.integerValue
        }
        return sum
    }
}