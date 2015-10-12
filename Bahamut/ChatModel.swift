//
//  ChatModel.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import ChatFramework
import UIKit

class ShareChatHub : NSNotificationCenter
{
    static let NotReadMessageChanged = "ShareChatHub:NotReadMessageChanged"
    var me:ShareLinkUser!
    var shareThing:ShareThing!
    private var _chats:[ChatModel] = [ChatModel]()
    
    func addChatModel(chatModel:ChatModel)
    {
        _chats.insert(chatModel, atIndex: 0)
    }
    
    func getSortChats() -> [ChatModel]
    {
        _chats.sortInPlace { (a, b) -> Bool in
            return a.newMsgTime.timeIntervalSince1970 < b.newMsgTime.timeIntervalSince1970
        }
        return _chats
    }
}

class ChatModel : NSNotificationCenter,UUMegItemDataSource
{
    static let NotReadMessageChanged = "ChatModel:NotReadMessageChanged"
    override init()
    {
        msgItems = [UUMsgItem]();
        chatTitle = "Message"
        newMsgTime = DateHelper.stringToDate("2015-10-10")
        messageService = ServiceContainer.getService(MessageService)
        userService = ServiceContainer.getService(UserService)
        fileService = ServiceContainer.getService(FileService)
    }
    
    private var messageService:MessageService!
    private var userService:UserService!
    private var fileService:FileService!
    private var needSort:Bool = false
    var chatIcon:String!
    var chatTitle:String!
    var previousTime:String!
    var newMsgTime:NSDate!
    var showNick:Bool = false
    var sharelinkers:[String]!{
        didSet{
            sharelinkerMap = [String:ShareLinkUser]()
            for userId in sharelinkers{
                let u = self.userService.getUser(userId)!
                sharelinkerMap.updateValue(u, forKey: userId)
            }
        }
    }
    var chatId:String!
    var audienceId:String!
    var shareId:String!
    private var sharelinkerMap:[String:ShareLinkUser]!
    func addMessage(newMsg:UUMsgItem)
    {
        needSort = true
        if newMsg.msgFrom == .Me
        {
            newMsg.senderId = userService.myUserId
        }
        let sendUser = sharelinkerMap[newMsg.senderId]
        newMsg.headIcon = sendUser?.headIconId
        if showNick
        {
            newMsg.nick = sendUser?.noteName
        }
        let now = NSDate()
        newMsg.timeString = now.toAccurateDateTimeString()
        newMsg.previousTime = previousTime
        if newMsg.msgFrame.showTime
        {
            previousTime = newMsg.timeString
        }
        msgItems.append(newMsg)
        if newMsg.msgFrom == .Me
        {
            var msgText:String!
            var msgData:NSData!
            var msgType:MessageType!
            switch newMsg.msgType
            {
            case .Text:
                msgType = MessageType.Text;
                msgText = (newMsg as! UUMsgTextItem).message
            case .Picture:
                msgType = MessageType.Picture;
                msgData = UIImageJPEGRepresentation((newMsg as! UUmsgPictureItem).image, 1)
            case .Voice:
                msgType = MessageType.Voice;
                let m = (newMsg as! UUMsgVoiceItem);
                msgData = m.voice;
                msgText = m.voiceTimeSec.description
            }
            let msgEntity = messageService.saveNewMessage("\(now.timeIntervalSince1970.hashValue.description)_\(arc4random())", chatId: chatId, type: msgType, time: now, senderId: userService.myUserId, msgText: msgText, data: msgData)
            msgEntity.isRead = true
            msgEntity.isSend = false
            msgEntity.saveModified()
            messageService.sendMessage(shareId, audienceId: audienceId, msg: msgEntity)
        }
    }
    
    func clearNotReadMessageNotify()
    {
        
    }
    
    func loadPreviousMessage() -> Int
    {
        var msgEntities:[MessageEntity]!
        if let tailMsg = dataSource.first
        {
            msgEntities = messageService.getMessage(chatId, limit: 7, beforeTime: tailMsg.time)
        }else
        {
            msgEntities = messageService.getMessage(chatId, limit: 7, beforeTime: NSDate())
        }
        var items = msgEntities.map { messageEntityToUUMsgItem($0) }
        items = items.reverse()
        for var i:Int = items.count - 1; i >= 0; i--
        {
            if i > 0
            {
                items[i].previousTime = items[i - 1].time.description
            }
            msgItems.insert(items[i], atIndex: 0)
        }
        return msgEntities.count
    }
    
    private func messageEntityToUUMsgItem(entity:MessageEntity) -> UUMsgItem
    {
        var msgItem:UUMsgItem!
        switch entity.type
        {
        case MessageType.Text.rawValue:
            let m = UUMsgTextItem()
            m.message = entity.msgText
            m.msgType = UUMessageType.Text
            msgItem = m
        case MessageType.Picture.rawValue:
            let m = UUmsgPictureItem()
            m.image = UIImage(data: entity.msgData)
            m.msgType = UUMessageType.Picture
            msgItem = m
        case MessageType.Voice.rawValue:
            let m = UUMsgVoiceItem()
            m.voice = entity.msgData
            m.voiceTimeSec = Int(entity.msgText) ?? 0
            m.msgType = UUMessageType.Voice
            msgItem = m
        default:
            print("loadPreviousMessage error")
        }
        if let senderUser = self.sharelinkerMap[entity.senderId]
        {
            msgItem.headIcon = senderUser.headIconId
            if self.showNick
            {
                msgItem.nick = senderUser.noteName
            }
        }
        msgItem.senderId = entity.senderId
        msgItem.timeString = entity.time.description
        msgItem.msgFrom = entity.senderId == self.userService.myUserId ? UUMessageFrom.Me : UUMessageFrom.Other
        return msgItem
    }
    
    var dataSource:[UUMsgItem]{
        return msgItems
    }
    
    private(set) var msgItems:[UUMsgItem]!
}
