//
//  ModelExtension.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: Model Enity
extension BahamutObject
{
    func saveModel()
    {
        PersistentManager.sharedInstance.saveModel(self)
    }
    
    static func saveObjectOfArray<T:BahamutObject>(arr:[T])
    {
        for item in arr
        {
            item.saveModel()
        }
    }
    
    static func deleteObjectArray(arr:[BahamutObject])
    {
        PersistentManager.sharedInstance.removeModels(arr)
    }
}

extension Array
{
    func saveBahamutObjectModels(){
        if self.count > 0 && (self.first! is BahamutObject){
            self.forEach({ (element) -> () in
                if let e = element as? BahamutObject{
                    e.saveModel()
                }
            })
        }
    }
}

class ModelExtensionConstant
{
    static let coreDataModelId = "BahamutModel"
    
    static let modelArrCacheName = "[Sharelink.AllModel]"
    
    static let idFieldName = "id"
    static let entityName = "ModelEntity"
}

class ModelExtension: PersistentExtensionProtocol
{
    static var defaultInstance:ModelExtension!
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
    func useModelExtension(dbFileUrl:NSURL,momdBundle:NSBundle)
    {
        self.useExtension(ModelExtension()) { (ext) -> Void in
            ModelExtension.defaultInstance = ext
            ext.coreData.initManager(ModelExtensionConstant.coreDataModelId, dbFileUrl: dbFileUrl,momdBundle: momdBundle)
        }
    }
    
    func saveModelChangesDelay()
    {
        ModelExtension.defaultInstance.coreData.saveContextDelay()
    }
    
    func saveModelChanges()
    {
        ModelExtension.defaultInstance.coreData.saveNow()
    }
    
    func clearAllModelData()
    {
        ModelExtension.defaultInstance.coreData.deleteAll(ModelExtensionConstant.entityName)
        clearCache()
    }
    
    func getModel<T:BahamutObject>(type:T.Type,idValue:String) -> T?
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
            if let cellModel = ModelExtension.defaultInstance.coreData.getCellById(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValue: indexIdValue) as? ModelEntity
            {
                let jsonString = cellModel.serializableValue
                let model = T(json: jsonString)
                cache.setObject(model, forKey: idValue)
                return model
            }
        }
        return nil
    }
    
    func getModels<T:BahamutObject>(type:T.Type ,idValues:[String]) -> [T]
    {
        let typename = type.description()
        let cache = getCache(typename)
        let notCacheIds = idValues.filter{
            cache.objectForKey($0) == nil
            }.map{"\(typename):\($0)"}
        
        if let cells = ModelExtension.defaultInstance.coreData.getCellsByIds(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValues: notCacheIds)as? [ModelEntity]
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
    
    func getAllModel<T:BahamutObject>(type:T.Type) -> [T]
    {
        let typename = type.description()
        let cache = getCache(ModelExtensionConstant.modelArrCacheName)
        let predicate = NSPredicate(format: "\(ModelExtensionConstant.idFieldName) LIKE %@", argumentArray: ["\(typename)*"])
        let result = ModelExtension.defaultInstance.coreData.getCells(ModelExtensionConstant.entityName,predicate: predicate).map{ obj -> T in
            let entity = obj as! ModelEntity
            return T(json: entity.serializableValue)
        }
        cache.setObject(result, forKey: typename)
        return result
    }
    
    func getAllModelFromCache<T:BahamutObject>(type:T.Type) -> [T]
    {
        let typename = type.description()
        let cache = getCache(ModelExtensionConstant.modelArrCacheName)
        if let result = cache.objectForKey(typename) as? [T]
        {
            return result
        }
        return getAllModel(type)
    }
    
    func refreshCache<T:BahamutObject>(type:T.Type)
    {
        getAllModel(type)
    }
    
    func clearArrCache<T:BahamutObject>(type:T.Type)
    {
        let typeName = type.description()
        let arrCache = getCache(ModelExtensionConstant.modelArrCacheName)
        arrCache.removeObjectForKey(typeName)
    }
    
    func removeModel<T:BahamutObject>(model:T)
    {
        removeModels([model])
    }
    
    func removeModels<T:BahamutObject>(models:[T])
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
        ModelExtension.defaultInstance.coreData.deleteCellByIds(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValues: idValues)
        clearArrCache(T)
    }
    
    func saveModel<T:BahamutObject>(model:T)
    {
        //save in cache
        let typeName = model.classForCoder.description()
        let nsCache = self.getCache(typeName)
        let idValue = model.getObjectUniqueIdValue()
        let indexIdValue = "\(typeName):\(idValue)"
        nsCache.setObject(model, forKey: idValue)
        //save in coredata
        var jsonString = model.toJsonString()
        jsonString = jsonString.split("\n").map{$0.trim()}.joinWithSeparator("")
        if let cellModel = ModelExtension.defaultInstance.coreData.getCellById(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValue: indexIdValue) as? ModelEntity
        {
            cellModel.serializableValue = jsonString
        }else
        {
            let cellModel = ModelExtension.defaultInstance.coreData.insertNewCell(ModelExtensionConstant.entityName) as? ModelEntity
            cellModel?.serializableValue = jsonString
            cellModel?.id = indexIdValue
            cellModel?.modelType = typeName
        }
        ModelExtension.defaultInstance.coreData.saveContextDelay()
    }
}
