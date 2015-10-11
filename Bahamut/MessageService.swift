
//
//  ReplyService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class UserMessageListItem
{
    var userId:String!
    var shareId:String!
    var message:String!
    var time:NSDate!
}

class MessageService:NSNotificationCenter,ServiceProtocol
{
    @objc static var ServiceName:String {return "MessageService"}
    @objc func appStartInit() {}
    
    @objc func userLoginInit(userId: String) {}
    
    static let messageListUpdated = "messageListUpdated"
    
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
        cm.chatId = entity.chatId
        cm.sharelinkers = entity.getUsers()
        if cm.sharelinkers.count == 1{
            let user = uService.getUser(cm.sharelinkers.first!)
            cm.chatTitle = user?.noteName
            cm.chatIcon = user?.headIconId
        }else{
            cm.chatTitle = "chat hub"
        }
        return cm
    }
    
    func getChatIdWithUserOfShareId(shareId:String,userId:String) -> String
    {
        return "\(shareId)&\(userId)"
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
    
    func sendMessage(msg:MessageEntity)
    {
        
    }
    
    func getShareChatHub(shareId:String) -> ShareChatHub
    {
        let uService = ServiceContainer.getService(UserService)
        var shareChats = PersistentManager.sharedInstance.getShareChats(shareId)
        if shareChats.count == 0
        {
            let chatId = getChatIdWithUserOfShareId(shareId, userId: uService.myUserId)
            let newSCE = PersistentManager.sharedInstance.saveNewChat(shareId,chatId: chatId)
            newSCE.addUser(uService.myUserId)
            shareChats.append(newSCE)
        }
        let chatModels = shareChats.map{return self.getChatModel($0.chatId)}.filter{$0 != nil}
        let sc = ShareChatHub()
        for cm in chatModels
        {
            sc.addChatModel(cm)
        }
        return sc
    }
    
    func getShareIdNotReadMessageCount(shareId:String) -> UInt32
    {
        return 23
    }
}