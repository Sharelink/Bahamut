//
//  PersistentManager.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/6.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class PersistentManager
{
    static let sharedInstance: PersistentManager = {return PersistentManager()}()
    private var nsCacheDict = [String:NSCache]()
    private(set) var documentsPathUrl:NSURL!
    private(set) var documentsPath:String!
    private(set) var fileCacheDirUrl:NSURL!
    private(set) var rootUrl:NSURL!
    private(set) var tmpUrl:NSURL!
    private(set) var dbFileUrl:NSURL!
    
    init()
    {
        rootUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        tmpUrl = rootUrl.URLByAppendingPathComponent("tmp")
        if NSFileManager.defaultManager().fileExistsAtPath(tmpUrl.path!) == false
        {
            do
            {
                try NSFileManager.defaultManager().createDirectoryAtPath(tmpUrl.path!, withIntermediateDirectories: true, attributes: nil)
            }catch
            {
                NSLog("create tmp dir error")
            }
        }
    }
    
    func clearRootDir()
    {
        if let files = rootUrl.pathComponents
        {
            for file in files
            {
                do
                {
                    try NSFileManager.defaultManager().removeItemAtPath(file)
                }catch{
                    
                }
            }
        }
        
    }
    
    func initManager(dbFileName:String,documentsPathUrl:NSURL,fileCacheDirUrl:NSURL)
    {
        dbFileUrl = self.rootUrl.URLByAppendingPathComponent(dbFileName)
        CoreDataHelper.initNSManagedObjectContext(dbFileUrl)
        self.fileCacheDirUrl = fileCacheDirUrl
        self.documentsPathUrl = documentsPathUrl
        self.documentsPath = documentsPathUrl.path
    }
    
    func getCache(typename:String) -> NSCache
    {
        if let typeCache = nsCacheDict[typename]
        {
            return typeCache
        }else{
            let typeCache = NSCache()
            nsCacheDict[typename] = typeCache
            return typeCache
        }
    }
    
    func clearCache()
    {
        for (_,cache) in nsCacheDict
        {
            cache.removeAllObjects()
        }
    }

    func reset()
    {
        CoreDataHelper.deinitNSManagedObjectContext()
    }
    
    func deleteUserDb()
    {
        do
        {
            CoreDataHelper.deinitNSManagedObjectContext()
            try NSFileManager.defaultManager().removeItemAtURL(dbFileUrl)
        }catch
        {
            NSLog("deleteUserDb failed")
        }
    }
    
    func saveAll()
    {
        CoreDataHelper.save()
    }
}


extension NSManagedObject
{
    func saveModified() -> Bool
    {
        do
        {
            try CoreDataHelper.getEntityContext().save()
            return true
        }catch let error as NSError
        {
            NSLog(error.description)
            return false
        }
    }
}

//MARK: MessagePersistents
struct ChatConstrants
{
    static let chatEntityName = "ShareChatEntity"
    static let chatEntityShareIdFieldName = "shareId"
    static let chatEntityChatIdFieldName = "chatId"
    
    static let messageEntityName = "MessageEntity"
    static let messageEntityChatIdFieldName = "chatId"
    static let messageEntityMessageIdFieldName = "msgId"
}

extension PersistentManager
{
    func clearMessageEntities()
    {
        CoreDataHelper.deleteAll(ChatConstrants.chatEntityName)
        CoreDataHelper.deleteAll(ChatConstrants.messageEntityName)
    }
    
    func getShareChats(shareId:String) -> [ShareChatEntity]
    {
        if let result = CoreDataHelper.getCellsById(ChatConstrants.chatEntityName, idFieldName: ChatConstrants.chatEntityShareIdFieldName, idValue: shareId) as? [ShareChatEntity]
        {
            return result
        }else
        {
            return [ShareChatEntity]()
        }
    }
    
    func getShareChat(chatId:String) -> ShareChatEntity!
    {
        if let result = CoreDataHelper.getCellById(ChatConstrants.chatEntityName,idFieldName: ChatConstrants.chatEntityChatIdFieldName, idValue: chatId) as? ShareChatEntity
        {
            return result
        }
        return nil
    }
    
    func getMessage(chatId:String,limit:Int = 7,beforeTime:NSDate! = nil) -> [MessageEntity]
    {
        let sortDesc = NSSortDescriptor(key: "time", ascending: false)
        let predict = NSPredicate(format: "\(ChatConstrants.messageEntityChatIdFieldName) = %@ and time < %@", argumentArray: [chatId,beforeTime ?? NSDate()])
        if let result = CoreDataHelper.getCells(ChatConstrants.messageEntityName, predicate: predict, limit: limit, sortDescriptors: [sortDesc]) as? [MessageEntity]
        {
            return result
        }
        return [MessageEntity]()
    }
    
    func getMessage(msgId:String) -> MessageEntity!
    {
        if let result = CoreDataHelper.getCellById(ChatConstrants.messageEntityName,idFieldName: ChatConstrants.messageEntityMessageIdFieldName, idValue: msgId) as? MessageEntity
        {
            return result
        }
        return nil
    }
    
    func getNewMessage(msgId:String) -> MessageEntity!
    {
        if getMessage(msgId) == nil
        {
            if let newEntity = CoreDataHelper.insertNewCell(ChatConstrants.messageEntityName) as? MessageEntity
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
            if let newEntity = CoreDataHelper.insertNewCell(ChatConstrants.chatEntityName) as? ShareChatEntity
            {
                newEntity.chatId = chatId
                newEntity.shareId = shareId
                newEntity.saveModified()
                return newEntity
            }
        }
        return nil
    }
}

//MARK: FilePersistents

struct FilePersistentsConstrants
{
    static let fileEntityName = "FileInfoEntity"
    static let fileEntityIdFieldName = "fileId"
    static let uploadTaskEntityName = "UploadTask"
    static let uploadTaskEntityIdFieldName = "fileId"
}


extension FileInfoEntity
{
    func getObsoluteFilePath() -> String!
    {
        return PersistentManager.sharedInstance.getAbsoluteFilePath(self.localPath)
    }
}

extension PersistentManager
{
    func clearAllFileManageData()
    {
        CoreDataHelper.deleteAll(FilePersistentsConstrants.fileEntityName)
        CoreDataHelper.deleteAll(FilePersistentsConstrants.uploadTaskEntityName)
        do
        {
            try NSFileManager.defaultManager().removeItemAtPath(documentsPathUrl.path!)
            clearFileCacheDir()
            clearTmpDir()
        }catch
        {
            
        }
    }
    
    func clearFileCacheDir()
    {
        do
        {
            try NSFileManager.defaultManager().removeItemAtPath(fileCacheDirUrl.path!)
        }catch
        {
            NSLog("clearTmpDir error")
        }
    }
    
    func clearTmpDir()
    {
        do
        {
            try NSFileManager.defaultManager().removeItemAtPath(tmpUrl.path!)
        }catch
        {
            NSLog("clearTmpDir error")
        }
    }
    
    func fileSizeOf(localfilePath:String) -> Int
    {
        do{
            let fileSize = try NSFileManager.defaultManager().attributesOfItemAtPath(localfilePath)[NSFileSize] as! Int
            return fileSize
        }catch{
            return -1
        }
    }
    
    func storeTempFile(data:NSData,fileType:FileType) -> String!
    {
        let path = createTmpFileName(fileType)
        if storeFile(data, filePath: path)
        {
            return path
        }
        return nil
    }
    
    func storeFile(data:NSData, filePath:String) -> Bool
    {
        return NSFileManager.defaultManager().createFileAtPath(filePath, contents: data, attributes: nil)
    }
    
    func deleteFile(filePath:String) -> Bool
    {
        do
        {
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
            return true
        }catch
        {
            return false
        }
    }
    
    func bindFileIdAndPath(fileId:String,data:NSData, filePath:String) -> FileInfoEntity?
    {
        if storeFile(data, filePath: filePath)
        {
            return bindFileIdAndPath(fileId, fileExistsPath: filePath)
        }else
        {
            return nil
        }
    }
    
    func bindFileIdAndPath(fileId:String,fileExistsPath:String) -> FileInfoEntity?
    {
        var relativePath:String!
        if let index = fileExistsPath.rangeOfString(documentsPath)?.last
        {
            let i = index.advancedBy(2) //advance 2 to trim '/' operator
            relativePath = fileExistsPath.substringFromIndex(i)
        }else
        {
            relativePath = fileExistsPath
        }
        let absolutePath = documentsPathUrl.URLByAppendingPathComponent(relativePath).path!
        if NSFileManager.defaultManager().fileExistsAtPath(absolutePath)
        {
            if let fileEntity = getFile(fileId)
            {
                fileEntity.localPath = relativePath
                fileEntity.saveModified()
                return fileEntity
            }else if let fileEntity = CoreDataHelper.insertNewCell(FilePersistentsConstrants.fileEntityName) as? FileInfoEntity
            {
                fileEntity.localPath = relativePath
                fileEntity.fileId = fileId
                fileEntity.saveModified()
                return fileEntity
            }
        }
        return nil
    }
    
    func getAbsoluteFilePath(relativePath:String) -> String
    {
        return documentsPathUrl.URLByAppendingPathComponent(relativePath).path!
    }
    
    func getFile(fileId:String!) -> FileInfoEntity?
    {
        if fileId == nil || fileId.isEmpty
        {
            return nil
        }
        let cache = getCache(FilePersistentsConstrants.fileEntityName)
        if let fileEntity = cache.objectForKey(fileId) as? FileInfoEntity
        {
            return fileEntity
        }else if let fileEntity = CoreDataHelper.getCellById(FilePersistentsConstrants.fileEntityName,
            idFieldName: FilePersistentsConstrants.fileEntityIdFieldName, idValue: fileId) as? FileInfoEntity
        {
            return fileEntity
        }else
        {
            return nil
        }
    }
    
    func createTmpFileName(fileType:FileType,fileName:String! = nil) -> String
    {
        if fileName == nil
        {
            return tmpUrl.URLByAppendingPathComponent("\(Int(NSDate().timeIntervalSince1970))\(fileType.FileSuffix)").path!
        }else
        {
            return tmpUrl.URLByAppendingPathComponent("\(fileName)\(fileType.FileSuffix)").path!
        }
    }
    
    func createCacheFileName(fileId:String,fileType:FileType) -> String
    {
        let localStoreFileDir = fileCacheDirUrl.URLByAppendingPathComponent("\(fileType.rawValue)")
        return localStoreFileDir.URLByAppendingPathComponent("/\(fileId)\(fileType.FileSuffix)").path!
    }
    
    func getFilePathFromCachePath(fileId:String,type:FileType!) -> String!
    {
        let path = createCacheFileName(fileId,fileType: type)
        if NSFileManager.defaultManager().fileExistsAtPath(path)
        {
            return path
        }
        return nil
    }
    
    func getImageFilePath(fileId:String?) -> String!
    {
        if fileId == nil
        {
            return nil
        }
        if let path = getFilePathFromCachePath(fileId!, type: FileType.Image)
        {
            return path
        }else if let entify = getFile(fileId)
        {
            return getAbsoluteFilePath(entify.localPath)
        }
        return nil
    }
    
    func getImage(fileId:String?) -> UIImage?
    {
        if fileId == nil
        {
            return nil
        }
        let cache = getCache("UIImage")
        if let image = cache.objectForKey(fileId!) as? UIImage
        {
            return image
        }else if let image = UIImage(named: fileId!)
        {
            cache.setObject(image, forKey: fileId!)
            return image
        }else if let path = getImageFilePath(fileId)
        {
            if let image = UIImage(contentsOfFile: path)
            {
                cache.setObject(image, forKey: fileId!)
                return image
            }
        }
        return nil
    }
}

//MARK: Model Enity
extension ShareLinkObject
{
    func saveModel()
    {
        PersistentManager.sharedInstance.saveModel(self)
    }
    
    static func saveObjectOfArray(arr:[ShareLinkObject])
    {
        for item in arr
        {
            item.saveModel()
        }
    }
    
    static func deleteObjectArray(arr:[ShareLinkObject])
    {
        PersistentManager.sharedInstance.removeModels(arr)
    }
}

struct ModelEntityConstants
{
    static let modelArrCacheName = "[Sharelink.AllModel]"
    
    static let idFieldName = "id"
    static let entityName = "ModelEntity"
}

extension PersistentManager
{
    func clearAllModelData()
    {
        CoreDataHelper.deleteAll(ModelEntityConstants.entityName)
        clearCache()
    }
    
    func getModel<T:ShareLinkObject>(type:T.Type,idValue:String) -> T?
    {
        if String.isNullOrWhiteSpace(idValue)
        {
            return nil
        }
        let typename = type.description()
        let cache = getCache(typename)
        
        //get from cache
        if let model = cache.objectForKey(idValue) as? T
        {
            return model
        }else
        {
            //read from core data
            let indexIdValue = "\(typename):\(idValue)"
            if let cellModel = CoreDataHelper.getCellById(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFieldName, idValue: indexIdValue) as? ModelEntity
            {
                let jsonString = cellModel.serializableValue
                let model = T(json: jsonString)
                cache.setObject(model, forKey: idValue)
                return model
            }
        }
        return nil
    }
    
    func getModels<T:ShareLinkObject>(type:T.Type ,idValues:[String]) -> [T]
    {
        let typename = type.description()
        let cache = getCache(typename)
        let notCacheIds = idValues.filter{
            cache.objectForKey($0) == nil
            }.map{"\(typename):\($0)"}
        
        if let cells = CoreDataHelper.getCellsByIds(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFieldName, idValues: notCacheIds)as? [ModelEntity]
        {
            for entity in cells
            {
                let jsonString = entity.serializableValue
                let model = T(json: jsonString)
                cache.setObject(model, forKey: model.getObjectUniqueIdValue())
            }
        }
        
        let result = idValues.map{
            cache.objectForKey($0) as? T
        }
        
        return result.filter{$0 != nil}.map{$0!}
    }
    
    func getAllModel<T:ShareLinkObject>(type:T.Type) -> [T]
    {
        let typename = type.description()
        let cache = getCache(ModelEntityConstants.modelArrCacheName)
        let predicate = NSPredicate(format: "\(ModelEntityConstants.idFieldName) LIKE %@", argumentArray: ["\(typename)*"])
        let result = CoreDataHelper.getCells(ModelEntityConstants.entityName,predicate: predicate).map{ obj -> T in
            let entity = obj as! ModelEntity
            return T(json: entity.serializableValue)
        }
        cache.setObject(result, forKey: typename)
        return result
    }
    
    func getAllModelFromCache<T:ShareLinkObject>(type:T.Type) -> [T]
    {
        let typename = type.description()
        let cache = getCache(ModelEntityConstants.modelArrCacheName)
        if let result = cache.objectForKey(typename) as? [T]
        {
            return result
        }
        return getAllModel(type)
    }
    
    func refreshCache<T:ShareLinkObject>(type:T.Type)
    {
        getAllModel(type)
    }
    
    func clearArrCache<T:ShareLinkObject>(type:T.Type)
    {
        let typeName = type.description()
        let arrCache = getCache(ModelEntityConstants.modelArrCacheName)
        arrCache.removeObjectForKey(typeName)
    }
    
    func removeModels<T:ShareLinkObject>(models:[T])
    {
        if models.count == 0
        {
            return
        }
        let typeName = models.first!.classForCoder.description()
        let cache = getCache(typeName)
        let idValues = models.map { (model) -> String in
            let idValue = model.getObjectUniqueIdValue()
            cache.removeObjectForKey(idValue)
            return "\(typeName):\(idValue)"
        }
        CoreDataHelper.deleteCellByIds(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFieldName, idValues: idValues)
        clearArrCache(T)
    }
    
    func saveModel(model:ShareLinkObject)
    {
        //save in cache
        //NSLog(model.classForCoder.description())
        let typeName = model.classForCoder.description()
        let nsCache = getCache(typeName)
        let idValue = model.getObjectUniqueIdValue()
        let indexIdValue = "\(typeName):\(idValue)"
        nsCache.setObject(model, forKey: idValue)
        //save in coredata
        let jsonString = model.toJsonString()
        if let cellModel = CoreDataHelper.getCellById(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFieldName, idValue: indexIdValue) as? ModelEntity
        {
            cellModel.serializableValue = jsonString
        }else
        {
            let cellModel = CoreDataHelper.insertNewCell(ModelEntityConstants.entityName) as? ModelEntity
            cellModel?.serializableValue = jsonString
            cellModel?.id = indexIdValue
            cellModel?.modelType = typeName
        }
        do  {
            try CoreDataHelper.getEntityContext().save()
        }catch{
            
        }
    }
}
