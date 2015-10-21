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

class CoreDataHelper {
    
    static func initNSManagedObjectContext(dbFileUrl:NSURL)
    {
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDel.initmanagedObjectContext(dbFileUrl)
    }
    
    static func deinitNSManagedObjectContext()
    {
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDel.deinitManagedObjectContext()
    }
    
    static func getEntityContext()-> NSManagedObjectContext
    {
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
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
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) IN %@", argumentArray: [idValues])
        request.returnsObjectsAsFaults = false
        do{
            let resultSet = try getEntityContext().executeFetchRequest(request)
            let objects = resultSet.map{ item -> NSManagedObject in
                return item as! NSManagedObject
            }
            for obj in objects
            {
                getEntityContext().deleteObject(obj)
            }
            try getEntityContext().save()
        }catch let error as NSError{
            print(error.description)
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
        try context.save()
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
            try context.save()
        }catch let ex as NSError{
            print(ex.description)
            print("delete entity:\(entityName) error")
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
            print(error.description)
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
    static func save()
    {
        do
        {
            try getEntityContext().save()
        }catch
        {
            print("context save error")
        }
    }
}