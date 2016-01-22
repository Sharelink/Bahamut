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
    @objc static var ServiceName:String {return "File Service"}
    
    private(set) var fileManager:NSFileManager!
    private(set) var documentsPathUrl:NSURL!
    private(set) var localStorePathUrl:NSURL!
    private var fetchingIdMap = [String:String]()
    private var uploadingIdMap = [String:String]()
    
    @objc func appStartInit() {
        PersistentManager.sharedInstance.appInit(SharelinkConfig.appName)
    }
    
    @objc func userLoginInit(userId: String) {
        initUserFoldersWithUserId(userId)
        initPersistentsExtensions(userId)
        initAliOSSManager()
        fetchingIdMap.removeAll()
        uploadingIdMap.removeAll()
        self.setServiceReady()
    }
    
    @objc func userLogout(userId: String) {
        PersistentManager.sharedInstance.clearTmpDir()
        PersistentManager.sharedInstance.clearCache()
        PersistentManager.sharedInstance.release()
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

    
    private func initUserFoldersWithUserId(userId:String)
    {
        fileManager = NSFileManager.defaultManager()
        initDocumentUrl(userId)
        initLocalStoreDir()
    }
    
    private func initPersistentsExtensions(userId:String)
    {
        PersistentManager.sharedInstance.useLocalFilesExtension(self.documentsPathUrl.URLByAppendingPathComponent("file.sqlite"),documentDirUrl: self.documentsPathUrl)
        PersistentManager.sharedInstance.useModelExtension(self.documentsPathUrl.URLByAppendingPathComponent("model.sqlite"))
        PersistentManager.sharedInstance.useMessageExtension(self.documentsPathUrl.URLByAppendingPathComponent("message.sqlite"))
        
        UpdateCoreDataHelper.getUpdater(userId).update(userId)
    }
    
    
    private func initDocumentUrl(userId:String)
    {
        documentsPathUrl = PersistentManager.sharedInstance.rootUrl.URLByAppendingPathComponent(userId)
        PersistentManager.sharedInstance.createDir(documentsPathUrl)
    }
    
    private func initLocalStoreDir()
    {
        localStorePathUrl = documentsPathUrl.URLByAppendingPathComponent("localStore")
        PersistentManager.sharedInstance.initFileDir(localStorePathUrl)
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
        if let path = Sharelink.mainBundle.pathForResource(fileId, ofType: nil)
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

