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
    static func readTextFile(_ fileUrl:URL) -> String?
    {
        return readTextFile(fileUrl.path)
    }
    
    static func readTextFile(_ filePath:String) -> String?
    {
        do
        {
            return try String(contentsOfFile: filePath)
        }catch
        {
            return nil
        }
    }
    
    static func isDirectory(_ url:URL) -> Bool
    {
        var isDir = ObjCBool(true)
        return FileManager.default.fileExists(atPath: url.path,isDirectory: &isDir)
    }
    
    static func fileExists(_ fileUrl:URL) -> Bool
    {
        return fileExists(fileUrl.path)
    }
    
    static func fileExists(_ filePath:String) -> Bool
    {
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    static func fileSizeOf(_ localfilePath:String) -> Int
    {
        do{
            let fileSize = try FileManager.default.attributesOfItem(atPath: localfilePath)[FileAttributeKey.size] as! Int
            return fileSize
        }catch{
            return -1
        }
    }
    
    @discardableResult
    static func moveFile(_ sourcePath:String,destinationPath:String) -> Bool
    {
        do
        {
            try FileManager.default.moveItem(atPath: sourcePath, toPath: destinationPath)
            return true
        }catch let err as NSError
        {
            if fileExists(sourcePath) == false{
                debugLog("No Source File:%@", sourcePath)
            }else if fileExists(destinationPath){
                debugLog("Destination Dir Not Exists:%@", destinationPath)
            }else{
                debugLog("Move file error:%@", err.description)
            }
            return false
        }
    }
    
    @discardableResult
    static func storeFile(_ data:Data, filePath:String) -> Bool
    {
        return FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    
    @discardableResult
    static func deleteFile(_ filePath:String) -> Bool
    {
        do
        {
            try FileManager.default.removeItem(atPath: filePath)
            return true
        }catch
        {
            return false
        }
    }
    
    static func generateTmpFileName()->String{
        return "\(String(format: "%.0f", Date().timeIntervalSince1970 * 1000))_\(random() % 100)"
    }
    
}
