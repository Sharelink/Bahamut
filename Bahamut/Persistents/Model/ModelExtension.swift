//
//  ModelExtension.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

//MARK: Model Enity
extension BahamutObject
{
    func saveModel()
    {
        PersistentManager.sharedInstance.saveModel(self)
    }
    
    static func saveObjectOfArray<T:BahamutObject>(_ arr:[T])
    {
        for item in arr
        {
            item.saveModel()
        }
    }
    
    static func deleteObjectArray(_ arr:[BahamutObject])
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
    
    static let modelArrCacheName = "[Bahamut.AllModel]"
    
    static let idFieldName = "id"
    static let entityName = "ModelEntity"
}

class ModelExtension: PersistentExtensionProtocol
{
    static var defaultInstance:ModelExtension!
    fileprivate(set) var coreData = CoreDataManager()
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
    func useModelExtension(_ dbFileUrl:URL,momdBundle:Bundle)
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
    }
    
    func getModel<T:BahamutObject>(_ type:T.Type,idValue:String) -> T?
    {
        if String.isNullOrWhiteSpace(idValue)
        {
            return nil
        }
        let typename = type.description()
        //read from core data
        let indexIdValue = "\(typename):\(idValue)"
        if let cellModel = ModelExtension.defaultInstance.coreData.getCellById(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValue: indexIdValue) as? ModelEntity
        {
            let jsonString = cellModel.serializableValue
            let model = T.fromJsonString(json: jsonString, T())
            return model
        }
        
        return nil
    }
    
    func getModels<T:BahamutObject>(_ type:T.Type ,idValues:[String]) -> [T?]?
    {
        if let cells = ModelExtension.defaultInstance.coreData.getCellsByIds(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValues: idValues) as? [ModelEntity?]
        {
            var result = [T?]()
            let t = T()
            for entity in cells
            {
                if let et = entity{
                    let jsonString = et.serializableValue
                    let model = T.fromJsonString(json: jsonString, t)
                    result.append(model)
                }else{
                    result.append(nil)
                }
            }
            return result
        }else{
            return nil
        }
    }
    
    @discardableResult
    func getAllModel<T:BahamutObject>(_ type:T.Type) -> [T]
    {
        let typename = type.description()
        let predicate = NSPredicate(format: "\(ModelExtensionConstant.idFieldName) LIKE %@", argumentArray: ["\(typename):*"])
        let result = ModelExtension.defaultInstance.coreData.getCells(ModelExtensionConstant.entityName,predicate: predicate).map{ obj -> T in
            let entity = obj as! ModelEntity
            let model = T.fromJsonString(json: entity.serializableValue, T())
            return model
        }
        return result
    }
    
    func getAllModelFromCache<T:BahamutObject>(_ type:T.Type) -> [T]
    {
        return getAllModel(type)
    }
    
    func removeAllModels<T:BahamutObject>(_ type:T.Type) -> [T]{
        let arr = getAllModel(type)
        removeModels(arr)
        return arr
    }
    
    func refreshCache<T:BahamutObject>(_ type:T.Type)
    {
        getAllModel(type)
    }
    
    func clearArrCache<T:BahamutObject>(_ type:T.Type)
    {
    }
    
    func removeModel<T:BahamutObject>(_ model:T)
    {
        removeModels([model])
    }
    
    func removeModels<T:BahamutObject>(_ m:T,idArray:[String]) {
        if idArray.count == 0 {
            return
        }
        let typeName = m.classForCoder.description()
        let idValues = idArray.map { (id) -> String in
            return "\(typeName):\(id)"
        }
        ModelExtension.defaultInstance.coreData.deleteCellByIds(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValues: idValues)
        saveModelChanges()
        clearArrCache(T.self)
    }
    
    func removeModels<T:BahamutObject>(_ models:[T])
    {
        if models.count == 0
        {
            return
        }
        let typeName = models.first!.classForCoder.description()
        let idValues = models.map { (model) -> String in
            let idValue = model.getObjectUniqueIdValue()
            return "\(typeName):\(idValue)"
        }
        ModelExtension.defaultInstance.coreData.deleteCellByIds(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValues: idValues)
        saveModelChanges()
        clearArrCache(T.self)
    }
    
    func saveModel<T:BahamutObject>(_ model:T)
    {
        //save in cache
        let typeName = model.classForCoder.description()
        let idValue = model.getObjectUniqueIdValue()
        let indexIdValue = "\(typeName):\(idValue)"
        var jsonString = model.toJsonString()
        jsonString = jsonString.split("\n").map{$0.trim()}.joined(separator: "")
        if let cellModel = ModelExtension.defaultInstance.coreData.getCellById(ModelExtensionConstant.entityName, idFieldName: ModelExtensionConstant.idFieldName, idValue: indexIdValue) as? ModelEntity
        {
            cellModel.serializableValue = jsonString
        }else
        {
            if let cellModel = ModelExtension.defaultInstance.coreData.insertNewCell(ModelExtensionConstant.entityName) as? ModelEntity{
                cellModel.serializableValue = jsonString
                cellModel.id = indexIdValue
                cellModel.modelType = typeName
            }
            
        }
        ModelExtension.defaultInstance.coreData.saveContextDelay()
    }
}
