//
//  PersistentManager.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/6.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

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
}

//MARK: FileReletionshipEntity
extension PersistentManager
{
    private var fileEntityName:String{return "FileRelationshipEntity"}
    
    func getImage(imageId:String,var filePath:String) -> UIImage
    {
        let cache = getCache("UIImage")
        if let image = cache.objectForKey(imageId) as? UIImage
        {
            return image
        }else
        {
            if let data = NSFileManager.defaultManager().contentsAtPath(filePath)
            {
                let image = UIImage(data: data)
                cache.setObject(image!, forKey: imageId)
                return image!
            }else if let image = UIImage(named: imageId)
            {
                cache.setObject(image, forKey: imageId)
                return image
            }
            return UIImage(named: "defaultView")!
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
}

struct ModelEntityConstants
{
    static let idFielldName = "id"
}

extension PersistentManager
{
    var entityName:String{return "ModelEntity"}
    
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
            if let cellModel = CoreDataHelper.getCellById(entityName, idFieldName: ModelEntityConstants.idFielldName, idValue: indexIdValue) as? ModelEntity
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
        return CoreDataHelper.getAllCells(entityName,idFieldName: ModelEntityConstants.idFielldName,typeName: typename).map{ obj -> T in
            let entity = obj as! ModelEntity
            return T(json: entity.serializableValue)
        }
    }
    
    func saveModel(model:ShareLinkObject)
    {
        //save in cache
        println(model.classForCoder.description())
        let typeName = model.classForCoder.description()
        var nsCache = getCache(typeName)
        let idValue = model.valueForKey(model.getObjectUniqueIdName()) as! String
        let indexIdValue = "\(typeName):\(idValue)"
        nsCache.setObject(model, forKey: indexIdValue)
        //save in coredata
        let jsonString = model.toJsonString()
        if let cellModel = CoreDataHelper.getCellById(entityName, idFieldName: ModelEntityConstants.idFielldName, idValue: indexIdValue) as? ModelEntity
        {
            cellModel.serializableValue = jsonString
        }else
        {
            let cellModel = CoreDataHelper.insertNewCell(entityName) as? ModelEntity
            cellModel?.serializableValue = jsonString
            cellModel?.id = indexIdValue
            cellModel?.modelType = typeName
        }
        CoreDataHelper.getEntityContext().save(nil)
    }
}
