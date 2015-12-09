//
//  PersistentFileHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/9.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: PersistentFileHelper
class PersistentFileHelper
{
    
    static func fileExists(filePath:String) -> Bool
    {
        return NSFileManager.defaultManager().fileExistsAtPath(filePath)
    }
    
    static func fileSizeOf(localfilePath:String) -> Int
    {
        do{
            let fileSize = try NSFileManager.defaultManager().attributesOfItemAtPath(localfilePath)[NSFileSize] as! Int
            return fileSize
        }catch{
            return -1
        }
    }
    
    static func moveFile(sourcePath:String,destinationPath:String) -> Bool
    {
        do
        {
            try NSFileManager.defaultManager().moveItemAtPath(sourcePath, toPath: destinationPath)
            return true
        }catch let err as NSError
        {
            NSLog("Move file error:%@", err.description)
            return false
        }
    }
    
    static func storeFile(data:NSData, filePath:String) -> Bool
    {
        return NSFileManager.defaultManager().createFileAtPath(filePath, contents: data, attributes: nil)
    }
    
    static func deleteFile(filePath:String) -> Bool
    {
        do
        {
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
            return true
        }catch
        {
            return false
        }
    }
    
}
