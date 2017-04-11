//
//  Persisitents.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/1.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//MARK: CoreDataManager
class CoreDataManager {
    fileprivate var changeTimes = 0
    fileprivate let contextLock = NSRecursiveLock()
    
    fileprivate var coreDataModelId = "Bahamut"
    fileprivate var dbFileUrl:URL!

    func getEntityContext()-> NSManagedObjectContext
    {
        contextLock.lock()
        let context: NSManagedObjectContext = self.managedObjectContext
        contextLock.unlock()
        return context
    }
    
    //MARK: New
    func insertNewCell(_ entityName:String)->NSManagedObject
    {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: getEntityContext()) 
    }
    
    //MARK: Delete
    func deleteCellByIds(_ entityName:String, idFieldName:String, idValues:[String])
    {
        DispatchQueue.main.async { () -> Void in
            let objs = (self.getCellsByIds(entityName, idFieldName: idFieldName, idValues: idValues)?.filter{$0 != nil}.map{$0!}) ?? [NSManagedObject]()
            do{
                try self.deleteObjects(objs)
            }catch let error as NSError{
                debugLog(error.description)
            }
        }
    }
    
    func deleteCellById(_ entityName:String, idFieldName:String, idValue:String)
    {
        deleteCellByIds(entityName, idFieldName: idFieldName, idValues: [idValue])
    }
    
    func deleteObject(_ object:NSManagedObject)
    {
        getEntityContext().delete(object)
    }
    
    func deleteObjects(_ objects:[NSManagedObject]) throws
    {
        let context = getEntityContext()
        for obj in objects
        {
            context.delete(obj)
        }
        saveContextDelay()
    }
    
    func deleteAll(_ entityName:String)
    {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        do{
            let context = getEntityContext()
            let resultSet = try context.fetch(request).map{$0 as! NSManagedObject}
            for obj in resultSet
            {
                context.delete(obj)
            }
            saveContextDelay()
        }catch let ex as NSError{
            debugLog(ex.description)
            debugLog("delete entity:\(entityName) error")
        }
    }
    
    //MARK: Query
    func getCellsByIds(_ entityName:String, idFieldName:String, idValues:[String])->[NSManagedObject?]?
    {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) IN %@", argumentArray: [idValues])
        request.returnsObjectsAsFaults = false
        do{
            let resultSet = try getEntityContext().fetch(request)
            return resultSet.map{ item -> NSManagedObject? in
                return item as? NSManagedObject
            }
        }catch _ as NSError{
            return nil
        }
    }
    
    func getCells(_ entityName:String,predicate:NSPredicate?,offset:Int = 0,limit:Int = -1,sortDescriptors:[NSSortDescriptor]! = nil) -> [NSManagedObject]
    {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchOffset = offset
        if limit != -1
        {
            request.fetchLimit = limit
        }
        do{
            let resultSet = try getEntityContext().fetch(request)
            return resultSet.map{ item -> NSManagedObject in
                return item as! NSManagedObject
            }
        }catch{
            
        }
        return [NSManagedObject]()
    }
    
    func getCellsById(_ entityName:String, idFieldName:String, idValue:String,offset:Int = 0,limit:Int = -1,sortDescriptors:[NSSortDescriptor]! = nil) -> [NSManagedObject]?
    {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) = %@", argumentArray: [idValue])
        request.sortDescriptors = sortDescriptors
        request.fetchOffset = offset
        if limit != -1
        {
            request.fetchLimit = limit
        }
        request.returnsObjectsAsFaults = false
        do{
            let resultSet = try getEntityContext().fetch(request)
            return resultSet as? [NSManagedObject]
        }catch{
            
        }
        return nil
    }
    
    func getCellById(_ entityName:String, idFieldName:String, idValue:String) -> NSManagedObject?
    {
        return getCellsById(entityName, idFieldName: idFieldName, idValue: idValue)?.first
    }
    
    //MARK: Update
    func saveContextDelay()
    {
        contextLock.lock()
        var saveFlag = false
        changeTimes += 1
        if changeTimes >= 23
        {
            saveFlag = true
            changeTimes = 0
        }
        if saveFlag
        {
            contextLock.unlock()
            saveNow()
        }else{
            contextLock.unlock()
        }
    }
    
    func saveNow()
    {
        contextLock.lock()
        self.saveContext()
        contextLock.unlock()
    }
    
    //MARK: Base Managed Core Data Object
    var managedObjectModel: NSManagedObjectModel!
    
    fileprivate func initManagedObjectModel(_ momdBundle:Bundle){
        if managedObjectModel == nil{
            if let modelURL = momdBundle.url(forResource: self.coreDataModelId, withExtension: "momd"){
                managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
            }else{
                //If fatal here,remove the xcdatamodelid files, and readd the files to project
                fatalError("Momd File Not Found:\(self.coreDataModelId)")
            }
        }
    }
    
    fileprivate var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    fileprivate func initPersistentStoreCoordinator(_ momdBundle:Bundle) -> NSPersistentStoreCoordinator{
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        initManagedObjectModel(momdBundle)
        let optionsDictionary = [NSMigratePersistentStoresAutomaticallyOption:NSNumber(value: true as Bool),NSInferMappingModelAutomaticallyOption:NSNumber(value: true as Bool)]
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let currentPersistentStore = dbFileUrl
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: currentPersistentStore, options: optionsDictionary)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            debugLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            abort()
        }
        
        return coordinator
    }
    
    func initManager(_ coreDataModelId:String!,dbFileUrl:URL,momdBundle:Bundle)
    {
        contextLock.lock()
        self.coreDataModelId = coreDataModelId
        self.dbFileUrl = dbFileUrl
        self.persistentStoreCoordinator = initPersistentStoreCoordinator(momdBundle)
        let coordinator = self.persistentStoreCoordinator
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        contextLock.unlock()
    }
    
    func deinitManager()
    {
        contextLock.lock()
        saveContext()
        persistentStoreCoordinator = nil
        managedObjectContext = nil
        contextLock.unlock()
    }
    
    fileprivate(set) var managedObjectContext: NSManagedObjectContext!
    
    // MARK: - Core Data Saving support
    
    fileprivate func saveContext () {
        if managedObjectContext == nil
        {
            return
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                debugLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    //MARK: - Destroy db file
    func destroyDbFile()
    {
        deinitManager()
        contextLock.lock()
        do{
            try FileManager.default.removeItem(at: dbFileUrl)
        }catch let err as NSError{
            debugLog(err.debugDescription)
            debugLog("Destroy Db File Error:\(dbFileUrl.path)")
        }
        contextLock.unlock()
    }
}
