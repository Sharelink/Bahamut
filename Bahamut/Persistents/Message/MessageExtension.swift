//
//  MessageExtension.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: MessagePersistents
struct MessageExtensionConstant
{
    static let chatEntityName = "ShareChatEntity"
    static let chatEntityShareIdFieldName = "shareId"
    static let chatEntityChatIdFieldName = "chatId"
    
    static let messageEntityName = "MessageEntity"
    static let messageEntityChatIdFieldName = "chatId"
    static let messageEntityMessageIdFieldName = "msgId"
    
    static let coreDataModelId = "BahamutMessage"
}

class MessageExtension: PersistentExtensionProtocol
{
    static var defaultInstance:MessageExtension!
    private(set) var coreData = CoreDataManager()
    
    func releaseExtension() {
        coreData.deinitManager()
    }
    
    func destroyExtension() {
        coreData.destroyDbFile()
    }
    
    func resetExtension() {
    }
    
    func storeImmediately() {
        coreData.saveNow()
    }
}

extension PersistentManager
{
    func useMessageExtension(dbFileUrl:NSURL,momdBundle:NSBundle)
    {
        self.useExtension(MessageExtension()) { (ext) -> Void in
            MessageExtension.defaultInstance = ext
            ext.coreData.initManager(MessageExtensionConstant.coreDataModelId, dbFileUrl: dbFileUrl,momdBundle: momdBundle)
        }
    }
    
    func clearMessageEntities()
    {
        MessageExtension.defaultInstance.coreData.deleteAll(MessageExtensionConstant.chatEntityName)
        MessageExtension.defaultInstance.coreData.deleteAll(MessageExtensionConstant.messageEntityName)
    }
    
    func getShareChats(shareId:String) -> [ShareChatEntity]
    {
        if let result = MessageExtension.defaultInstance.coreData.getCellsById(MessageExtensionConstant.chatEntityName, idFieldName: MessageExtensionConstant.chatEntityShareIdFieldName, idValue: shareId) as? [ShareChatEntity]
        {
            return result
        }else
        {
            return [ShareChatEntity]()
        }
    }
    
    func getShareChat(chatId:String) -> ShareChatEntity!
    {
        if let result = MessageExtension.defaultInstance.coreData.getCellById(MessageExtensionConstant.chatEntityName,idFieldName: MessageExtensionConstant.chatEntityChatIdFieldName, idValue: chatId) as? ShareChatEntity
        {
            return result
        }
        return nil
    }
    
    func getMessage(chatId:String,limit:Int = 7,beforeTime:NSDate! = nil) -> [MessageEntity]
    {
        let sortDesc = NSSortDescriptor(key: "time", ascending: false)
        let predict = NSPredicate(format: "\(MessageExtensionConstant.messageEntityChatIdFieldName) = %@ and time < %@", argumentArray: [chatId,beforeTime ?? NSDate()])
        if let result = MessageExtension.defaultInstance.coreData.getCells(MessageExtensionConstant.messageEntityName, predicate: predict, limit: limit, sortDescriptors: [sortDesc]) as? [MessageEntity]
        {
            return result
        }
        return [MessageEntity]()
    }
    
    func getMessage(msgId:String) -> MessageEntity!
    {
        if let result = MessageExtension.defaultInstance.coreData.getCellById(MessageExtensionConstant.messageEntityName,idFieldName: MessageExtensionConstant.messageEntityMessageIdFieldName, idValue: msgId) as? MessageEntity
        {
            return result
        }
        return nil
    }
    
    func getNewMessage(msgId:String) -> MessageEntity!
    {
        if getMessage(msgId) == nil
        {
            if let newEntity = MessageExtension.defaultInstance.coreData.insertNewCell(MessageExtensionConstant.messageEntityName) as? MessageEntity
            {
                newEntity.msgId = msgId
                return newEntity
            }
        }
        return nil
    }
    
    func saveNewChat(shareId:String,chatId:String) -> ShareChatEntity!
    {
        if getShareChat(chatId) == nil
        {
            if let newEntity = MessageExtension.defaultInstance.coreData.insertNewCell(MessageExtensionConstant.chatEntityName) as? ShareChatEntity
            {
                newEntity.chatId = chatId
                newEntity.shareId = shareId
                MessageExtension.defaultInstance.coreData.saveNow()
                return newEntity
            }
        }
        return nil
    }
    
    func saveMessageChanges()
    {
        MessageExtension.defaultInstance.coreData.saveNow()
    }
}
