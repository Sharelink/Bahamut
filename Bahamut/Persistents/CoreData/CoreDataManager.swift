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
    private var changeTimes = 0
    private let contextLock = NSRecursiveLock()
    
    private var coreDataModelId = "Bahamut"
    private var dbFileUrl:NSURL!

    func getEntityContext()-> NSManagedObjectContext
    {
        contextLock.lock()
        let context: NSManagedObjectContext = self.managedObjectContext
        contextLock.unlock()
        return context
    }
    
    //MARK: New
    func insertNewCell(entityName:String)->NSManagedObject
    {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: getEntityContext()) 
    }
    
    //MARK: Delete
    func deleteCellByIds(entityName:String, idFieldName:String, idValues:[String])
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let objs = self.getCellsByIds(entityName, idFieldName: idFieldName, idValues: idValues)
            do{
                try self.deleteObjects(objs)
            }catch let error as NSError{
                NSLog(error.description)
            }
        }
    }
    
    func deleteCellById(entityName:String, idFieldName:String, idValue:String)
    {
        deleteCellByIds(entityName, idFieldName: idFieldName, idValues: [idValue])
    }
    
    func deleteObject(object:NSManagedObject)
    {
        getEntityContext().deleteObject(object)
    }
    
    func deleteObjects(objects:[NSManagedObject]) throws
    {
        let context = getEntityContext()
        for obj in objects
        {
            context.deleteObject(obj)
        }
        saveContextDelay()
    }
    
    func deleteAll(entityName:String)
    {
        let request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        do{
            let context = getEntityContext()
            let resultSet = try context.executeFetchRequest(request).map{$0 as! NSManagedObject}
            for obj in resultSet
            {
                context.deleteObject(obj)
            }
            saveContextDelay()
        }catch let ex as NSError{
            NSLog(ex.description)
            NSLog("delete entity:\(entityName) error")
        }
    }
    
    //MARK: Query
    func getCellsByIds(entityName:String, idFieldName:String, idValues:[String])->[NSManagedObject]
    {
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) IN %@", argumentArray: [idValues])
        request.returnsObjectsAsFaults = false
        do{
            let resultSet = try getEntityContext().executeFetchRequest(request)
            return resultSet.map{ item -> NSManagedObject in
                return item as! NSManagedObject
            }
        }catch let error as NSError{
            NSLog(error.description)
            return [NSManagedObject]()
        }
    }
    
    func getCells(entityName:String,predicate:NSPredicate?,limit:Int = -1,sortDescriptors:[NSSortDescriptor]! = nil) -> [NSManagedObject]
    {
        let request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if limit != -1
        {
            request.fetchLimit = limit
        }
        do{
            let resultSet = try getEntityContext().executeFetchRequest(request)
            return resultSet.map{ item -> NSManagedObject in
                return item as! NSManagedObject
            }
        }catch{
            
        }
        return [NSManagedObject]()
    }
    
    func getCellsById(entityName:String, idFieldName:String, idValue:String,limit:Int = -1,sortDescriptors:[NSSortDescriptor]! = nil) -> [NSManagedObject]?
    {
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) = %@", argumentArray: [idValue])
        request.sortDescriptors = sortDescriptors
        if limit != -1
        {
            request.fetchLimit = limit
        }
        request.returnsObjectsAsFaults = false
        do{
            let resultSet = try getEntityContext().executeFetchRequest(request)
            return resultSet as? [NSManagedObject]
        }catch{
            
        }
        return nil
    }
    
    func getCellById(entityName:String, idFieldName:String, idValue:String) -> NSManagedObject?
    {
        return getCellsById(entityName, idFieldName: idFieldName, idValue: idValue)?.first
    }
    
    //MARK: Update
    func saveContextDelay()
    {
        var saveFlag = false
        contextLock.lock()
        changeTimes++
        if changeTimes >= 23
        {
            saveFlag = true
            changeTimes = 0
        }
        contextLock.unlock()
        if saveFlag
        {
            saveNow()
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
    
    private func initManagedObjectModel(momdBundle:NSBundle){
        if managedObjectModel == nil{
            // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
            let modelURL = momdBundle.URLForResource(self.coreDataModelId, withExtension: "momd")!
            managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)!
        }
    }
    
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    private func initPersistentStoreCoordinator(momdBundle:NSBundle) -> NSPersistentStoreCoordinator{
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        initManagedObjectModel(momdBundle)
        let optionsDictionary = [NSMigratePersistentStoresAutomaticallyOption:NSNumber(bool: true),NSInferMappingModelAutomaticallyOption:NSNumber(bool: true)]
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let currentPersistentStore = dbFileUrl
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: currentPersistentStore, options: optionsDictionary)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            abort()
        }
        
        return coordinator
    }
    
    func initManager(coreDataModelId:String!,dbFileUrl:NSURL,momdBundle:NSBundle)
    {
        contextLock.lock()
        self.coreDataModelId = coreDataModelId
        self.dbFileUrl = dbFileUrl
        self.persistentStoreCoordinator = initPersistentStoreCoordinator(momdBundle)
        let coordinator = self.persistentStoreCoordinator
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
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
    
    private(set) var managedObjectContext: NSManagedObjectContext!
    
    // MARK: - Core Data Saving support
    
    private func saveContext () {
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
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
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
            try NSFileManager.defaultManager().removeItemAtURL(dbFileUrl)
        }catch let err as NSError{
            NSLog(err.debugDescription)
            NSLog("Destroy Db File Error:\(dbFileUrl.path)")
        }
        contextLock.unlock()
    }
}