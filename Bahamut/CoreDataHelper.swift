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
    static func getEntityContext()-> NSManagedObjectContext
    {
        var appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        return context
    }
    
    static func insertNewCell(entityName:String)->NSManagedObject
    {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: getEntityContext()) as! NSManagedObject
    }
    
    static func getCellByIds(entityName:String, idFieldName:String, idValues:[String])->[NSManagedObject]
    {
        var request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) IN %@", argumentArray: [idValues])
        request.returnsObjectsAsFaults = false
        var result = [NSManagedObject]()
        if let resultSet = getEntityContext().executeFetchRequest(request, error: nil)
        {
            return resultSet.map{ item -> NSManagedObject in
                return item as! NSManagedObject
            }
        }
        return result
    }
    
    static func getAllCells(entityName:String, idFieldName:String, typeName:String)->[NSManagedObject]
    {
        var request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "\(idFieldName) LIKE %@", argumentArray: ["\(typeName)*"])
        if let resultSet = getEntityContext().executeFetchRequest(request, error: nil)
        {
            return resultSet.map{ item -> NSManagedObject in
                return item as! NSManagedObject
            }
        }
        return [NSManagedObject]()
    }
    
    static func getCellById(entityName:String, idFieldName:String, idValue:String) -> NSManagedObject?
    {
        var request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "\(idFieldName) = %@", argumentArray: [idValue])
        request.returnsObjectsAsFaults = false
        if let resultSet = getEntityContext().executeFetchRequest(request, error: nil)
        {
            for obj in resultSet
            {
                if let mobj = obj as? NSManagedObject
                {
                    return mobj
                }
            }
        }
        return nil
    }
}