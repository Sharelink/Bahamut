//
//  ChatModel.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit


let ShareChatHubNewMessageChanged = "ShareChatHubNewMessageChanged"
let ChatHubCurrentChatModelChanged = "CurrentChatModelChanged"
let ChatHubCurrentChatMessageChanged = "CurrentChatMessageChanged"
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
    var me:Sharelinker!
    var shareId:String!{
        didSet{
            ServiceContainer.getService(ChatService).addObserver(self, selector: #selector(ShareChatHub.newChatModelCreated(_:)), name: NewChatModelsCreated, object: nil)
        }
    }
    private var _chats:[ChatModel] = [ChatModel]()
    var inChatView:Bool = false{
        didSet{
            if inChatView
            {
                currentChatModel.clearNotReadMessage()
            }
        }
    }
    var currentChatModel:ChatModel!{
        didSet{
            currentChatModel.loadPreviousMessage()
            currentChatModel.clearNotReadMessage()
            postNotificationName(ChatHubCurrentChatModelChanged, object: self)
        }
    }
    
    func newChatModelCreated(a:NSNotification)
    {
        if let newChatModels = a.userInfo?[NewCreatedChatModels] as? [ChatModel]
        {
            let models = newChatModels.filter{$0.shareId == shareId}
            if models.count > 0
            {
                for m in models
                {
                    addChatModel(m)
                }
                postNotificationName(ShareChatHubNewMessageChanged, object: self)
            }
        }
    }
    
    func addChatModel(chatModel:ChatModel)
    {
        chatModel.addObserver(self, selector: #selector(ShareChatHub.chatModelChanged(_:)), name: ChatModelNewMessageChanged, object: nil)
        _chats.insert(chatModel, atIndex: 0)
    }
    
    func chatModelChanged(a:NSNotification)
    {
        if let cm = a.userInfo?[ChangedChatModel] as? ChatModel
        {
            if inChatView && cm.chatId == currentChatModel.chatId
            {
                cm.clearNotReadMessage()
                postNotificationName(ChatHubCurrentChatMessageChanged, object: self)
            }
            postNotificationName(ShareChatHubNewMessageChanged, object: self)
        }
        
    }
    
    func removeModel(chatId:String)
    {
        _chats.removeElement{
            $0.removeObserver(self)
            return $0.chatId == chatId
        }
    }
    
    func getSortChats() -> [ChatModel]
    {
        _chats.sortInPlace { (a, b) -> Bool in
            return a.newMsgTime.compare(b.newMsgTime) == .OrderedDescending
        }
        return _chats
    }
    
    deinit
    {
        for c in _chats
        {
            c.removeObserver(self)
        }
        _chats.removeAll()
        ServiceContainer.getService(ChatService).removeObserver(self)
    }
}

let ChatModelNewMessageChanged = "ChatModelNewMessageChanged"
let ChangedChatModel = "ChangedChatModel"

class ChatModel : NSNotificationCenter,UUMegItemDataSource
{
    
    override init()
    {
        super.init()
        msgItems = [UUMsgItem]();
        chatTitle = "Message"
        newMsgTime = DateHelper.stringToDate("2015-10-10")
        messageService = ServiceContainer.getService(ChatService)
        userService = ServiceContainer.getService(UserService)
        fileService = ServiceContainer.getService(FileService)
        shareService = ServiceContainer.getService(ShareService)
        messageService.addObserver(self, selector: #selector(ChatModel.receiveNewMessage(_:)), name: ChatService.messageServiceNewMessageReceived, object: self.chatId)
    }
    
    deinit
    {
        messageService.removeObserver(self)
    }
    
    private var messageService:ChatService!
    private var userService:UserService!
    private var fileService:FileService!
    private var shareService:ShareService!
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
    
    var sendImageQuality:CGFloat = 0.7
    
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
        newMsg.avatar = PersistentManager.sharedInstance.getImageFilePath(sendUser?.avatarId) ?? ""
        if showNick
        {
            newMsg.nick = sendUser?.getNoteName()
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
                msgData = UIImageJPEGRepresentation((newMsg as! UUmsgPictureItem).image, sendImageQuality)
                msgText = "img"
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
            PersistentManager.sharedInstance.saveMessageChanges()
            messageService.sendMessage(chatId, msg: msgEntity,shareId: shareId,audienceId: audienceId)
            let sortableObject = shareService.getShareThing(shareId).getSortableObject()
            sortableObject.compareValue = NSNumber(double:NSDate().timeIntervalSince1970)
            sortableObject.saveModel()
            shareService.setSortableObjects([sortableObject])
        }
    }
    
    func clearNotReadMessage()
    {
        chatEntity.newMessage = 0
        PersistentManager.sharedInstance.saveMessageChanges()
    }
    
    func receiveNewMessage(a:NSNotification)
    {
        if let userInfo = a.userInfo
        {
            if let msgs = userInfo[ChatServiceNewMessageEntities] as? [MessageEntity]
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
                for i in (items.count - 1).stride(through: 0, by: -1)
                {
                    if i > 0
                    {
                        items[i].previousTime = items[i - 1].time.description
                    }
                }
                newMsgTime = items.last?.time
                msgItems.appendContentsOf(items)
                postNotificationName(ChatModelNewMessageChanged, object: self,userInfo: [ChangedChatModel:self])
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
        if let firstMsgTime = items.first?.time
        {
            if firstMsgTime.timeIntervalSince1970 > self.newMsgTime.timeIntervalSince1970
            {
                self.newMsgTime = items.first?.time
            }
        }
        items = items.reverse()
        for i in (items.count - 1).stride(through: 0, by: -1)
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
            let voiceTime = entity.msgText
            m.voiceTimeSec = Int(voiceTime) ?? 0
            m.msgType = UUMessageType.Voice
            msgItem = m
        default:
            NSLog("messageEntityToUUMsgItem error")
        }
        if let senderUser = userService.getUser(entity.senderId)
        {
            msgItem.avatar = PersistentManager.sharedInstance.getImageFilePath(senderUser.avatarId) ?? ""
            if self.showNick
            {
                msgItem.nick = senderUser.getNoteName()
            }
        }
        msgItem.senderId = entity.senderId
        msgItem.timeString = entity.time.toAccurateDateTimeString()
        msgItem.msgFrom = entity.senderId == self.userService.myUserId ? UUMessageFrom.Me : UUMessageFrom.Other
        return msgItem
    }
    
}
