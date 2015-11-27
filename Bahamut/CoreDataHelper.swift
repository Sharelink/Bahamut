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

//MARK: NSManagedObject saveModified
extension NSManagedObject
{
    func saveModified()
    {
        CoreDataHelper.saveContextDelay()
    }
}

//MARK: CoreDataHelper
class CoreDataHelper {
    private static var changeTimes = 0
    private static let contextLock = NSRecursiveLock()
    static func initNSManagedObjectContext(dbFileUrl:NSURL)
    {
        contextLock.lock()
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDel.initmanagedObjectContext(dbFileUrl)
        contextLock.unlock()
    }
    
    static func deinitNSManagedObjectContext()
    {
        contextLock.lock()
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDel.deinitManagedObjectContext()
        contextLock.unlock()
    }
    
    static func getEntityContext()-> NSManagedObjectContext
    {
        contextLock.lock()
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        contextLock.unlock()
        return context
    }
    
    //MARK: New
    static func insertNewCell(entityName:String)->NSManagedObject
    {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: getEntityContext()) 
    }
    
    //MARK: Delete
    static func deleteCellByIds(entityName:String, idFieldName:String, idValues:[String])
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let objs = CoreDataHelper.getCellsByIds(entityName, idFieldName: idFieldName, idValues: idValues)
            do{
                try CoreDataHelper.deleteObjects(objs)
            }catch let error as NSError{
                NSLog(error.description)
            }
        }
    }
    
    static func deleteCellById(entityName:String, idFieldName:String, idValue:String)
    {
        deleteCellByIds(entityName, idFieldName: idFieldName, idValues: [idValue])
    }
    
    static func deleteObject(object:NSManagedObject)
    {
        getEntityContext().deleteObject(object)
    }
    
    static func deleteObjects(objects:[NSManagedObject]) throws
    {
        let context = getEntityContext()
        for obj in objects
        {
            context.deleteObject(obj)
        }
        saveContextDelay()
    }
    
    static func deleteAll(entityName:String)
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
    static func getCellsByIds(entityName:String, idFieldName:String, idValues:[String])->[NSManagedObject]
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
    
    static func getCells(entityName:String,predicate:NSPredicate?,limit:Int = -1,sortDescriptors:[NSSortDescriptor]! = nil) -> [NSManagedObject]
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
    
    static func getCellsById(entityName:String, idFieldName:String, idValue:String,limit:Int = -1,sortDescriptors:[NSSortDescriptor]! = nil) -> [NSManagedObject]?
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
    
    static func getCellById(entityName:String, idFieldName:String, idValue:String) -> NSManagedObject?
    {
        return getCellsById(entityName, idFieldName: idFieldName, idValue: idValue)?.first
    }
    
    //MARK: Update
    static func saveContextDelay()
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
    
    static func saveNow()
    {
        contextLock.lock()
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        app.saveContext()
        NSLog("Core Data Saved")
        contextLock.unlock()
    }
}