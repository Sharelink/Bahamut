//
//  UpdateCoreData1_0_8.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/9.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
class UpdateCoreData1:PersistentUpdateProtocol
{
    func update(obj: AnyObject?) {
        let userId = obj as! String
        NSLog("Updating Core Data From Version 1")
        importOldCoreDatas(userId)
        NSLog("Update Core Data Completed")
        UpdateCoreDataHelper.setCoreDataVersion(userId)
    }
    
    private func importOldCoreDatas(userId:String)
    {
        let dbFileUrl = PersistentManager.sharedInstance.rootUrl.URLByAppendingPathComponent("\(userId).sqlite")
        
        if PersistentFileHelper.fileExists(dbFileUrl.path!)
        {
            let oldCoreData = CoreDataManager()
            oldCoreData.initManager("Bahamut", dbFileUrl: dbFileUrl,momdBundle: Sharelink.mainBundle)
            NSLog("Importing Core Data Local File Entity")
            let fileInfos = oldCoreData.getCells(LocalFileExtensionConstant.fileEntityName, predicate: nil) as! [FileInfoEntity]
            for e in fileInfos
            {
                let newEntity = LocalFilesExtension.defaultInstance.coreData.insertNewCell(LocalFileExtensionConstant.fileEntityName) as! FileInfoEntity
                newEntity.fileId = e.fileId
                newEntity.fileType = e.fileType
                newEntity.localPath = e.localPath
            }
            
            let uptasks = oldCoreData.getCells(LocalFileExtensionConstant.uploadTaskEntityName, predicate: nil) as! [UploadTask]
            for u in uptasks
            {
                let newEntity = LocalFilesExtension.defaultInstance.coreData.insertNewCell(LocalFileExtensionConstant.uploadTaskEntityName) as! UploadTask
                newEntity.localPath = u.localPath
                newEntity.fileId = u.fileId
                newEntity.fileServerUrl = u.fileServerUrl
                newEntity.status = u.status
            }
            
            NSLog("File Entity Count:\(fileInfos.count + uptasks.count)")
            
            NSLog("Importing Core Data Model Entity")
            let models = oldCoreData.getCells(ModelExtensionConstant.entityName, predicate: nil) as! [ModelEntity]
            for m in models
            {
                let newEntity = ModelExtension.defaultInstance.coreData.insertNewCell(ModelExtensionConstant.entityName) as! ModelEntity
                newEntity.id = m.id
                newEntity.serializableValue = m.serializableValue
                newEntity.modelType = m.modelType
            }
            NSLog("Model Entity Count:\(models.count)")
            
            NSLog("Importing Core Data Message Entity")
            let chats = oldCoreData.getCells(MessageExtensionConstant.chatEntityName, predicate: nil) as! [ShareChatEntity]
            for c in chats
            {
                let newEntity = MessageExtension.defaultInstance.coreData.insertNewCell(MessageExtensionConstant.chatEntityName) as! ShareChatEntity
                newEntity.shareId = c.shareId
                newEntity.chatId = c.chatId
                newEntity.chatUsers = c.chatUsers
                newEntity.newMessage = c.newMessage
            }
            
            let messages = oldCoreData.getCells(MessageExtensionConstant.messageEntityName, predicate: nil) as! [MessageEntity]
            for m in messages
            {
                let newEntity = MessageExtension.defaultInstance.coreData.insertNewCell(MessageExtensionConstant.messageEntityName) as! MessageEntity
                newEntity.shareId  = m.shareId
                newEntity.chatId  = m.chatId
                newEntity.isRead = m.isRead
                newEntity.msgData  = m.msgData
                newEntity.msgId  = m.msgId
                newEntity.senderId  = m.senderId
                newEntity.msgText  = m.msgText
                newEntity.type = m.type
                newEntity.time = m.time
                newEntity.isSend = m.isSend
                newEntity.sendFailed = m.sendFailed
            }
            NSLog("Message Entity Count:\(chats.count + messages.count)")
            
            PersistentManager.sharedInstance.saveAll()
            oldCoreData.destroyDbFile()
        }
    }
    
}