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
        rootUrl = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        initDocumentUrl(userId)
        initLocalStoreDir()
        initFileCacheDir()
        PersistentManager.sharedInstance.initManager(rootUrl,fileCacheDirUrl: fileCachePathUrl)
    }
    
    private func initDocumentUrl(userId:String)
    {
        documentsPathUrl = rootUrl.URLByAppendingPathComponent(userId)
        if fileManager.fileExistsAtPath(documentsPathUrl.path!) == false
        {
            do
            {
                try fileManager.createDirectoryAtPath(documentsPathUrl.path!, withIntermediateDirectories: true, attributes: nil)
            }catch
            {
                print("create document dir error")
            }
        }
    }
    
    private func initLocalStoreDir()
    {
        localStorePathUrl = documentsPathUrl.URLByAppendingPathComponent("localStore")
        initFileDir(localStorePathUrl)
    }
    
    private func initFileCacheDir()
    {
        fileCachePathUrl = documentsPathUrl.URLByAppendingPathComponent("caches")
        initFileDir(fileCachePathUrl)
    }
    
    private func initFileDir(parentDirUrl:NSURL)
    {
        for item in FileType.allValues
        {
            let dir = parentDirUrl.URLByAppendingPathComponent("\(item.rawValue)")
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
        }
    }
    
    private(set) var fileManager:NSFileManager!
    private(set) var documentsPathUrl:NSURL!
    private(set) var localStorePathUrl:NSURL!
    private(set) var fileCachePathUrl:NSURL!
    private(set) var rootUrl:NSURL!
    
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
    
    func getFilePath(fileId:String!,type:FileType!) -> String!
    {
        if let path = NSBundle.mainBundle().pathForResource(fileId, ofType: nil)
        {
            return path
        }else if let path = PersistentManager.sharedInstance.getFile(fileId)?.getObsoluteFilePath()
        {
            return path
        }else
        {
            return PersistentManager.sharedInstance.getFilePathFromCachePath(fileId, type: type)
        }
    }
    
    func getLocalStoreDirPathOfFileType(fileType:FileType) -> String
    {
        return getLocalStoreDirUrlOfFileType(fileType).path!
    }
    
    func getLocalStoreDirUrlOfFileType(fileType:FileType) -> NSURL
    {
        return localStorePathUrl.URLByAppendingPathComponent("\(fileType.rawValue)")
    }
    
    func createLocalStoreFileName(fileType:FileType) -> String
    {
        return localStorePathUrl.URLByAppendingPathComponent("/\(Int(NSDate().timeIntervalSince1970))\(fileType.FileSuffix)").path!
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

