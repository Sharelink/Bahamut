//
//  FileService.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/1.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import Alamofire

class FileService: ServiceProtocol {
    @objc static var ServiceName:String {return "file service"}
    @objc func appStartInit() {
        
        
    }
    
    @objc func userLoginInit(userId: String) {
        initUserFoldersWithUserId(userId)
    }
    
    private func initUserFoldersWithUserId(userId:String)
    {
        fileManager = NSFileManager.defaultManager()
        documentsPathUrl = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0].URLByAppendingPathComponent(userId)
        if fileManager.fileExistsAtPath(documentsPathUrl.path!) == false
        {
            do
            {
                try fileManager.createDirectoryAtPath(documentsPathUrl.path!, withIntermediateDirectories: true, attributes: nil)
            }catch let error as NSError
            {
                print(error.description)
            }
        }
        initFileCacheDir()
        initFileDir()
        uploadQueue = [UploadTask]()
        initFileUploadProc()
        PersistentManager.sharedInstance.initManager(fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0])
    }
    
    private func initFileCacheDir()
    {
        fileCachePathUrl = documentsPathUrl.URLByAppendingPathComponent("caches")
        if !fileManager.fileExistsAtPath(fileCachePathUrl.path!)
        {
            do
            {
                try fileManager.createDirectoryAtPath(fileCachePathUrl.path!, withIntermediateDirectories: true, attributes: nil)
            }catch let error as NSError
            {
                print(error.description)
            }
        }
    }
    
    private func initFileDir()
    {
        for item in FileType.allValues
        {
            let dir = documentsPathUrl.URLByAppendingPathComponent("\(item.rawValue)")
            if fileManager.fileExistsAtPath(dir.path!) == false
            {
                do
                {
                    try fileManager.createDirectoryAtPath(dir.path!, withIntermediateDirectories: true, attributes: nil)
                }catch let error as NSError
                {
                    print(error.description)
                }
            }
            let localStoreFileDir = documentsPathUrl.URLByAppendingPathComponent("localStore/\(item.rawValue)")
            if fileManager.fileExistsAtPath(localStoreFileDir.path!) == false
            {
                do
                {
                    try fileManager.createDirectoryAtPath(localStoreFileDir.path!, withIntermediateDirectories: true, attributes: nil)
                }catch let error as NSError
                {
                    print(error.description)
                }
            }
            
        }
    }
    
    private(set) var uploadQueue:[UploadTask]!
    private(set) var fileManager:NSFileManager!
    private(set) var documentsPathUrl:NSURL!
    private(set) var fileCachePathUrl:NSURL!
    
    func clearUserDatas()
    {
        do
        {
            try fileManager.removeItemAtURL(documentsPathUrl)
            
        }catch let error as NSError
        {
            print(error.description)
        }
        PersistentManager.sharedInstance.clearAllFileManageData()
        PersistentManager.sharedInstance.clearAllModelData()
        PersistentManager.sharedInstance.clearCache()
        
    }
    
    func getFileByFileId(fileId:String!,var fileType:FileType!,returnCallback:(filePath:String!)->Void)
    {
        if let path = NSBundle.mainBundle().pathForResource(fileId, ofType: nil)
        {
            ProgressTaskWatcher.sharedInstance.missionCompleted(fileId, result: path)
            returnCallback(filePath: path)
        }else if let path = PersistentManager.sharedInstance.getFile(fileId)?.getObsoluteFilePath()
        {
            ProgressTaskWatcher.sharedInstance.missionCompleted(fileId, result: path)
            returnCallback(filePath: path)
        }else
        {
            if fileType == nil
            {
                fileType = FileType.getFileTypeByFileId(fileId)
                if fileType == .Raw
                {
                    if let fe = PersistentManager.sharedInstance.getFile(fileId)
                    {
                        
                        fileType = FileType.getFileType(fe.fileType.integerValue)
                    }
                }
            }
            fetch(fileId,fileType:fileType,callback: returnCallback)
        }
    }
    
    func getLocalStoreDirPathOfFileType(fileType:FileType) -> String
    {
        return getLocalStoreDirUrlOfFileType(fileType).path!
    }
    
    func getLocalStoreDirUrlOfFileType(fileType:FileType) -> NSURL
    {
        return documentsPathUrl.URLByAppendingPathComponent("localStore/\(fileType.rawValue)")
    }
    
    func createLocalStoreFileName(fileType:FileType) -> String
    {
        let localStoreFileDir = documentsPathUrl.URLByAppendingPathComponent("localStore/\(fileType.rawValue)")
        return localStoreFileDir.URLByAppendingPathComponent("/\(Int(NSDate().timeIntervalSince1970))\(fileType.FileSuffix)").path!
    }
    
    func createCacheFileName(fileType:FileType) -> String
    {
        let localStoreFileDir = fileCachePathUrl.URLByAppendingPathComponent("\(fileType.rawValue)")
        return localStoreFileDir.URLByAppendingPathComponent("/\(Int(NSDate().timeIntervalSince1970))\(fileType.FileSuffix)").path!
    }
    
    func moveFileTo(srcPath:String,destinationPath:String) -> Bool
    {
        do{
            try fileManager.moveItemAtPath(srcPath, toPath: destinationPath)
            return true
        }catch let error as NSError
        {
            print(error.description)
            return false
        }
    }
    
    func getLocalStoreDirFileURLs(fileType:FileType) -> [NSURL]
    {
        let dirURL = getLocalStoreDirUrlOfFileType(fileType)
        do{
            let files = try fileManager.contentsOfDirectoryAtURL(dirURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            return files
        }catch
        {
            return [NSURL]()
        }
    }
    
    func getLocalStoreDirFiles(fileType:FileType) -> [String]
    {
        return getLocalStoreDirFileURLs(fileType).map({ (url) -> String in
            return url.path!
        })
    }

}

