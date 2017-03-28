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
    fileprivate var nsCache = NSCache<AnyObject, AnyObject>()
    fileprivate(set) var rootUrl:URL!
    fileprivate(set) var tmpUrl:URL!
    fileprivate var extensions = [PersistentExtensionProtocol]()
    
    func appInit(_ appName:String)
    {
        rootUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(appName)
        tmpUrl = rootUrl.appendingPathComponent("tmp")
        createTmpDir()
    }
    
    func useExtension<T:PersistentExtensionProtocol>(_ ext:T,action:((_ ext:T)->Void)! = nil)
    {
        self.extensions.append(ext)
        if let handler = action
        {
            handler(ext)
        }
    }
    
    func initFileDir(_ parentDirUrl:URL)
    {
        for item in FileType.allValues
        {
            let dir = parentDirUrl.appendingPathComponent("\(item.rawValue)")
            createDir(dir)
        }
    }
    
    @discardableResult
    func createDir(_ dir:URL) -> Bool
    {
        if FileManager.default.fileExists(atPath: dir.path) == false
        {
            do
            {
                try FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
                return true
            }catch let error as NSError
            {
                debugLog(error.description)
                return false
            }
        }else
        {
            return true
        }
    }
    
    //MARK: tmp file
    @discardableResult
    func storeTempFile(_ data:Data,fileType:FileType) -> String!
    {
        let path = createTmpFileName(fileType)
        if PersistentFileHelper.storeFile(data, filePath: path)
        {
            return path
        }
        return nil
    }
    
    @discardableResult
    func createTmpFileName(_ fileType:FileType,fileName:String! = nil) -> String
    {
        if fileName == nil
        {
            return tmpUrl.appendingPathComponent("\(NSNumber(value: Date().timeIntervalSince1970 as Double).intValue)\(fileType.FileSuffix)").path
        }else
        {
            return tmpUrl.appendingPathComponent("\(fileName!)\(fileType.FileSuffix)").path
        }
    }
    
    func createTmpDir()
    {
        if FileManager.default.fileExists(atPath: tmpUrl.path) == false
        {
            do
            {
                try FileManager.default.createDirectory(atPath: tmpUrl.path, withIntermediateDirectories: true, attributes: nil)
            }catch
            {
                debugLog("create tmp dir error")
            }
        }
    }
    
    func clearTmpDir()
    {
        do
        {
            try FileManager.default.removeItem(atPath: tmpUrl.path)
        }catch
        {
            debugLog("clearTmpDir error")
        }
    }
    
    func resetTmpDir()
    {
        clearTmpDir()
        createTmpDir()
    }
    
    //MARK: root dir
    
    func getAbsoluteFilePath(_ relativePath:String) -> String
    {
        return rootUrl.appendingPathComponent(relativePath).path
    }
    
    func clearRootDir()
    {
        do
        {
            let rootpath = rootUrl.path
            try FileManager.default.removeItem(atPath: rootpath)
            debugLog("Root Dir Removed")
        }catch{
            debugLog("Root Dir Remove Error")
        }
        
    }
    
    //MARK: model cache
    func cacheModel(_ typename:String,modelId:String,model:AnyObject) {
        nsCache.setObject(model, forKey: "\(typename)_\(modelId)" as AnyObject)
    }
    
    func getCachedModel(_ typename:String,modelId:String) -> AnyObject? {
        return nsCache.object(forKey: "\(typename)_\(modelId)" as AnyObject)
    }
    
    func clearCache()
    {
        nsCache.removeAllObjects()
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
