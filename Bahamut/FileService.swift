//
//  FileService.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/1.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
//MARK: FileFetcher
protocol FileFetcher
{
    func startFetch(resourceUri:String,delegate:ProgressTaskDelegate)
}

//MARK: FilePathFileFetcher
class FilePathFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(filepath: String, delegate: ProgressTaskDelegate) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            delegate.taskCompleted(filepath, result: filepath)
        }
    }
    
    static let shareInstance:FileFetcher = {
        return FilePathFileFetcher()
    }()
}

extension FileService
{
    func getFileFetcherOfFilePath(fileType:FileType) -> FileFetcher
    {
        let fetcher = FilePathFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
}

//MARK: FileService
class FileService: ServiceProtocol {
    @objc static var ServiceName:String {return "file service"}
    
    private(set) var fileManager:NSFileManager!
    private(set) var documentsPathUrl:NSURL!
    private(set) var localStorePathUrl:NSURL!
    private(set) var fileCachePathUrl:NSURL!
    private(set) var rootUrl:NSURL!
    private var fetchingIdMap = [String:String]()
    private var uploadingIdMap = [String:String]()
    
    @objc func appStartInit() {
        
    }
    
    @objc func userLoginInit(userId: String) {
        initUserFoldersWithUserId(userId)
        initAliOSSManager()
        fetchingIdMap.removeAll()
        uploadingIdMap.removeAll()
    }
    
    @objc func userLogout(userId: String) {
        PersistentManager.sharedInstance.clearTmpDir()
        PersistentManager.sharedInstance.clearCache()
        PersistentManager.sharedInstance.reset()
    }
    
    func clearLocalStoreFiles()
    {
        do{
            try fileManager.removeItemAtURL(localStorePathUrl)
        }catch
        {
            NSLog("clearLocalStoreFiles Failed")
        }
    }
    
    func clearFileCacheFiles()
    {
        PersistentManager.sharedInstance.deleteFile(fileCachePathUrl.path!)
        initFileCacheDir()
    }
    
    private func initUserFoldersWithUserId(userId:String)
    {
        fileManager = NSFileManager.defaultManager()
        rootUrl = PersistentManager.sharedInstance.rootUrl
        initDocumentUrl(userId)
        initLocalStoreDir()
        initFileCacheDir()
        PersistentManager.sharedInstance.initManager("\(userId).sqlite",documentsPathUrl: rootUrl,fileCacheDirUrl: fileCachePathUrl)
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
                NSLog("create document dir error")
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
                    NSLog(error.description)
                }
            }
        }
    }

    private var fetchingLock = NSRecursiveLock()
    func setFetching(fileId:String)
    {
        fetchingLock.lock()
        self.fetchingIdMap[fileId] = "true"
        fetchingLock.unlock()
    }
    
    func fetchingFinished(fileId:String)
    {
        fetchingLock.lock()
        self.fetchingIdMap.removeValueForKey(fileId)
        fetchingLock.unlock()
    }
    
    func isFetching(fileId:String) -> Bool
    {
        fetchingLock.lock()
        let flag = fetchingIdMap.keys.contains(fileId)
        fetchingLock.unlock()
        return flag
    }
    
    func getFilePath(fileId:String!,type:FileType!) -> String!
    {
        if let path = NSBundle.mainBundle().pathForResource(fileId, ofType: nil)
        {
            return path
        }else if let path = PersistentManager.sharedInstance.getFilePathFromCachePath(fileId, type: type)
        {
            return path
        }else
        {
            return PersistentManager.sharedInstance.getStorageFileEntity(fileId)?.getObsoluteFilePath() ?? nil
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
        return getLocalStoreDirUrlOfFileType(fileType).URLByAppendingPathComponent("\(Int(NSDate().timeIntervalSince1970))\(fileType.FileSuffix)").path!
    }
    
    func moveFileTo(srcPath:String,destinationPath:String) -> Bool
    {
        do{
            try fileManager.moveItemAtPath(srcPath, toPath: destinationPath)
            return true
        }catch let error as NSError
        {
            NSLog(error.description)
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

