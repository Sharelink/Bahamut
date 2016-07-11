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


//MARK: PersistentManager
class PersistentManager
{
    static let sharedInstance: PersistentManager = {return PersistentManager()}()
    private var nsCacheDict = [String:NSCache]()
    private(set) var rootUrl:NSURL!
    private(set) var tmpUrl:NSURL!
    private var extensions = [PersistentExtensionProtocol]()
    
    func appInit(appName:String)
    {
        rootUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0].URLByAppendingPathComponent(appName)
        tmpUrl = rootUrl.URLByAppendingPathComponent("tmp")
        createTmpDir()
    }
    
    func useExtension<T:PersistentExtensionProtocol>(ext:T,action:((ext:T)->Void)! = nil)
    {
        self.extensions.append(ext)
        if let handler = action
        {
            handler(ext: ext)
        }
    }
    
    func initFileDir(parentDirUrl:NSURL)
    {
        for item in FileType.allValues
        {
            let dir = parentDirUrl.URLByAppendingPathComponent("\(item.rawValue)")
            createDir(dir)
        }
    }
    
    func createDir(dir:NSURL) -> Bool
    {
        if NSFileManager.defaultManager().fileExistsAtPath(dir.path!) == false
        {
            do
            {
                try NSFileManager.defaultManager().createDirectoryAtPath(dir.path!, withIntermediateDirectories: true, attributes: nil)
                return true
            }catch let error as NSError
            {
                NSLog(error.description)
                return false
            }
        }else
        {
            return true
        }
    }
    
    //MARK: tmp file
    
    func storeTempFile(data:NSData,fileType:FileType) -> String!
    {
        let path = createTmpFileName(fileType)
        if PersistentFileHelper.storeFile(data, filePath: path)
        {
            return path
        }
        return nil
    }
    
    func createTmpFileName(fileType:FileType,fileName:String! = nil) -> String
    {
        if fileName == nil
        {
            return tmpUrl.URLByAppendingPathComponent("\(NSNumber(double:NSDate().timeIntervalSince1970).integerValue)\(fileType.FileSuffix)").path!
        }else
        {
            return tmpUrl.URLByAppendingPathComponent("\(fileName)\(fileType.FileSuffix)").path!
        }
    }
    
    func createTmpDir()
    {
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
    
    func resetTmpDir()
    {
        clearTmpDir()
        createTmpDir()
    }
    
    //MARK: root dir
    
    func getAbsoluteFilePath(relativePath:String) -> String
    {
        return rootUrl.URLByAppendingPathComponent(relativePath).path!
    }
    
    func clearRootDir()
    {
        do
        {
            if let rootpath = rootUrl.path
            {
                try NSFileManager.defaultManager().removeItemAtPath(rootpath)
                NSLog("Root Dir Removed")
            }
        }catch{
            NSLog("Root Dir Remove Error")
        }
        
    }
    
    //MARK: model cache
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

    //MARK: db context
    
    func release()
    {
        for e in extensions
        {
            e.releaseExtension()
        }
        extensions.removeAll()
    }
    
    func saveAll()
    {
        for e in extensions
        {
            e.storeImmediately()
        }
    }
}
