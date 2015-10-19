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

let ShareChatHubNewMessageChanged = "ShareChatHubNewMessageChanged"

class ShareChatHub : NSNotificationCenter
{
    var newMessage:Int{
        var sum = 0
        for c in _chats
        {
            sum += c.chatEntity.newMessage.integerValue
        }
        return sum
    }
    var me:ShareLinkUser!
    var shareThing:ShareThing!
    private var _chats:[ChatModel] = [ChatModel]()
    
    func addChatModel(chatModel:ChatModel)
    {
        chatModel.addObserver(self, selector: "chatModelChanged:", name: ChatModelNewMessageChanged, object: nil)
        _chats.insert(chatModel, atIndex: 0)
    }
    
    func chatModelChanged(a:NSNotification)
    {
        postNotificationName(ShareChatHubNewMessageChanged, object: self)
    }
    
    func removeModel(chatId:String)
    {
        for var i = _chats.count; i>=0;i--
        {
            if _chats[i].chatId == chatId
            {
                _chats[i].removeObserver(self)
                _chats.removeAtIndex(i)
            }
        }
    }
    
    func getSortChats() -> [ChatModel]
    {
        _chats.sortInPlace { (a, b) -> Bool in
            return a.newMsgTime.compare(b.newMsgTime) == .OrderedAscending
        }
        return _chats
    }
    
    deinit
    {
        for c in _chats
        {
            c.removeObserver(self)
        }
    }
}

let ChatModelNewMessageChanged = "ChatModelNewMessageChanged"

class ChatModel : NSNotificationCenter,UUMegItemDataSource
{
    
    override init()
    {
        super.init()
        msgItems = [UUMsgItem]();
        chatTitle = "Message"
        newMsgTime = DateHelper.stringToDate("2015-10-10")
        messageService = ServiceContainer.getService(MessageService)
        userService = ServiceContainer.getService(UserService)
        fileService = ServiceContainer.getService(FileService)
        messageService.addObserver(self, selector: "receiveNewMessage:", name: MessageService.messageServiceNewMessageReceived, object: self.chatId)
    }
    
    deinit
    {
        messageService.removeObserver(self)
    }
    
    private var messageService:MessageService!
    private var userService:UserService!
    private var fileService:FileService!
    private var needSort:Bool = false
    var chatEntity:ShareChatEntity!
    var chatIcon:String!
    var chatTitle:String!
    var previousTime:String!
    var newMsgTime:NSDate!
    var showNick:Bool = false
    var sharelinkers:[String]!
    var chatId:String!
    var audienceId:String!
    var shareId:String!
    
    var dataSource:[UUMsgItem]{
        return msgItems
    }
    
    private(set) var msgItems:[UUMsgItem]!
    
    func addMessage(newMsg:UUMsgItem)
    {
        needSort = true
        if newMsg.msgFrom == .Me
        {
            newMsg.senderId = userService.myUserId
        }
        let sendUser = userService.getUser(newMsg.senderId)
        newMsg.avatar = PersistentManager.sharedInstance.getImageFilePath(sendUser?.avatarId)
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
            let msgId = "\(now.timeIntervalSince1970.hashValue.description)_\(arc4random())"
            let msgEntity = messageService.saveNewMessage(msgId, chatId: chatId,shareId: shareId, type: msgType, time: now, senderId: userService.myUserId, msgText: msgText, data: msgData)
            msgEntity.isRead = true
            msgEntity.isSend = false
            msgEntity.sendFailed = false
            msgEntity.saveModified()
            messageService.sendMessage(chatId, msg: msgEntity,shareId: shareId,audienceId: audienceId)
        }
    }
    
    func clearNotReadMessageNotify()
    {
        chatEntity.newMessage = 0
        chatEntity.saveModified()
        postNotificationName(ChatModelNewMessageChanged, object: self)
    }
    
    func receiveNewMessage(a:NSNotification)
    {
        if let userInfo = a.userInfo
        {
            if let msgs = userInfo[MessageServiceNewMessageEntities] as? [MessageEntity]
            {
                var items = msgs.filter{$0.chatId == self.chatId}.map{ self.messageEntityToUUMsgItem($0) }
                if items.count == 0
                {
                    return
                }
                items.sortInPlace({ (a, b) -> Bool in
                    return a.time.compare(b.time) == .OrderedAscending
                })
                if let lastMsg = dataSource.last
                {
                    items.first?.previousTime = lastMsg.timeString
                }
                for var i:Int = items.count - 1; i >= 0; i--
                {
                    if i > 0
                    {
                        items[i].previousTime = items[i - 1].time.description
                    }
                }
                newMsgTime = items.last?.time
                msgItems.appendContentsOf(items)
                chatEntity.newMessage = chatEntity.newMessage.integerValue + items.count
                chatEntity.saveModified()
                postNotificationName(ChatModelNewMessageChanged, object: self)
            }
        }
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
            print("messageEntityToUUMsgItem error")
        }
        if let senderUser = userService.getUser(entity.senderId)
        {
            msgItem.avatar = PersistentManager.sharedInstance.getImageFilePath(senderUser.avatarId)
            if self.showNick
            {
                msgItem.nick = senderUser.noteName
            }
        }
        msgItem.senderId = entity.senderId
        msgItem.timeString = entity.time.toAccurateDateTimeString()
        msgItem.msgFrom = entity.senderId == self.userService.myUserId ? UUMessageFrom.Me : UUMessageFrom.Other
        return msgItem
    }
    
}
