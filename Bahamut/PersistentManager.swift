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

}

//MARK: FilePersistents

struct FilePersistentsConstrants
{
    static let fileEntityName = "FileInfoEntity"
    static let fileEntityIdFieldName = "fileId"
    static let uploadTaskEntityName = "UploadTask"
    static let uploadTaskEntityIdFieldName = "fileId"
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
            print(error.description)
            return false
        }
    }
}

extension PersistentManager
{
    func clearAllFileManageData()
    {
        CoreDataHelper.deleteAll(FilePersistentsConstrants.fileEntityName)
        CoreDataHelper.deleteAll(FilePersistentsConstrants.uploadTaskEntityName)
    }
    
    func saveFile(fileId:String,data:NSData, filePath:String) -> FileInfoEntity?
    {
        if NSFileManager.defaultManager().createFileAtPath(filePath, contents: data, attributes: nil)
        {
            return saveFile(fileId, fileExistsPath: filePath)
        }else
        {
            return nil
        }
    }
    
    func saveFile(fileId:String,fileExistsPath:String) -> FileInfoEntity?
    {
        if NSFileManager.defaultManager().fileExistsAtPath(fileExistsPath)
        {
            if let fileEntity = getFile(fileId)
            {
                fileEntity.localPath = fileExistsPath
                fileEntity.saveModified()
                return fileEntity
            }else if let fileEntity = CoreDataHelper.insertNewCell(FilePersistentsConstrants.fileEntityName) as? FileInfoEntity
            {
                fileEntity.localPath = fileExistsPath
                fileEntity.fileId = fileId
                fileEntity.saveModified()
                return fileEntity
            }
        }
        return nil
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
        }else if let entify = getFile(fileId)
        {
            let image = UIImage(contentsOfFile: entify.localPath)
            cache.setObject(image!, forKey: fileId!)
            return image!
        }else if let image = UIImage(named: fileId!)
        {
            cache.setObject(image, forKey: fileId!)
            return image
        }else
        {
            return nil
        }
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
    static let idFielldName = "id"
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
        let typename = type.description()
        let cache = getCache(typename)
        
        let indexIdValue = "\(typename):\(idValue)"
        //get from cache
        if let model = cache.objectForKey(indexIdValue) as? T
        {
            return model
        }else
        {
            //read from core data
            if let cellModel = CoreDataHelper.getCellById(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFielldName, idValue: indexIdValue) as? ModelEntity
            {
                let jsonString = cellModel.serializableValue
                let model = T(json: jsonString)
                cache.setObject(model, forKey: "\(typename):\(idValue)")
                return model
            }
        }
        return nil
    }
    
    func getModels<T:ShareLinkObject>(type:T.Type ,idValues:[String]) -> [T]
    {
        var result:[T] = [T]()
        for id in idValues
        {
            if let model = getModel(type, idValue: id)
            {
                result.append(model)
            }
        }
        return result
    }
    
    func getAllModel<T:ShareLinkObject>(type:T.Type) -> [T]
    {
        let typename = type.description()
        let typesname = "[\(typename)]"
        let cache = getCache(typesname)
        let result = CoreDataHelper.getAllCells(ModelEntityConstants.entityName,idFieldName: ModelEntityConstants.idFielldName,typeName: typename).map{ obj -> T in
            let entity = obj as! ModelEntity
            return T(json: entity.serializableValue)
        }
        cache.setObject(result, forKey: typesname)
        return result
    }
    
    func getAllModelFromCache<T:ShareLinkObject>(type:T.Type) -> [T]
    {
        let typename = "[\(type.description())]"
        let cache = getCache(typename)
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
    
    func removeModels<T:ShareLinkObject>(models:[T])
    {
        let typeName = T().classForCoder.description()
        let idValues = models.map { (model) -> String in
            let idValue = model.getObjectUniqueIdValue()
            return "\(typeName):\(idValue)"
        }
        CoreDataHelper.deleteCellByIds(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFielldName, idValues: idValues)
    }
    
    func saveModel(model:ShareLinkObject)
    {
        //save in cache
        //print(model.classForCoder.description())
        let typeName = model.classForCoder.description()
        let nsCache = getCache(typeName)
        let idValue = model.getObjectUniqueIdValue()
        let indexIdValue = "\(typeName):\(idValue)"
        nsCache.setObject(model, forKey: indexIdValue)
        //save in coredata
        let jsonString = model.toJsonString()
        if let cellModel = CoreDataHelper.getCellById(ModelEntityConstants.entityName, idFieldName: ModelEntityConstants.idFielldName, idValue: indexIdValue) as? ModelEntity
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
