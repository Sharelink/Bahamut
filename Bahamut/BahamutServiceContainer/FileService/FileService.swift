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
    func startFetch(_ resourceUri:String,delegate:ProgressTaskDelegate)
}

//MARK: FilePathFileFetcher
class FilePathFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(_ filepath: String, delegate: ProgressTaskDelegate) {
        DispatchQueue.global().async {
            delegate.taskCompleted(filepath, result: filepath)
        }
    }
    
    static let shareInstance:FileFetcher = {
        return FilePathFileFetcher()
    }()
}

extension FileService
{
    func getFileFetcherOfFilePath(_ fileType:FileType) -> FileFetcher
    {
        let fetcher = FilePathFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
}

extension ServiceContainer{
    static func getFileService() -> FileService{
        return ServiceContainer.getService(FileService.self)
    }
}

//MARK: FileService
class FileService: ServiceProtocol {
    @objc static var ServiceName:String {return "File Service"}
    
    fileprivate(set) var fileManager:FileManager!
    fileprivate(set) var documentsPathUrl:URL!
    fileprivate(set) var localStorePathUrl:URL!
    fileprivate var fetchingIdMap = [String:String]()
    fileprivate var uploadingIdMap = [String:String]()
    fileprivate var mondBundle:Bundle!
    fileprivate var coreDataUpdater:PersistentUpdateProtocol!
    
    init(mondBundle:Bundle,coreDataUpdater:PersistentUpdateProtocol?)
    {
        self.mondBundle = mondBundle
        self.coreDataUpdater = coreDataUpdater
    }
    
    @objc func appStartInit(_ appName:String) {
        PersistentManager.sharedInstance.appInit(appName)
    }
    
    @objc func userLoginInit(_ userId: String) {
        initUserFoldersWithUserId(userId)
        initPersistentsExtensions(userId)
        fetchingIdMap.removeAll()
        uploadingIdMap.removeAll()
        self.setServiceReady()
    }
    
    @objc func userLogout(_ userId: String) {
        PersistentManager.sharedInstance.resetTmpDir()
        PersistentManager.sharedInstance.clearCache()
        PersistentManager.sharedInstance.release()
    }
    
    func clearLocalStoreFiles()
    {
        do{
            try fileManager.removeItem(at: localStorePathUrl)
        }catch
        {
            debugLog("clearLocalStoreFiles Failed")
        }
    }

    
    fileprivate func initUserFoldersWithUserId(_ userId:String)
    {
        fileManager = FileManager.default
        initDocumentUrl(userId)
        initLocalStoreDir()
    }
    
    fileprivate func initPersistentsExtensions(_ userId:String)
    {
        PersistentManager.sharedInstance.useLocalFilesExtension(self.documentsPathUrl.appendingPathComponent("file.sqlite"),documentDirUrl: self.documentsPathUrl,momdBundle: mondBundle)
        PersistentManager.sharedInstance.useModelExtension(self.documentsPathUrl.appendingPathComponent("model.sqlite"),momdBundle: mondBundle)
        PersistentManager.sharedInstance.useMessageExtension(self.documentsPathUrl.appendingPathComponent("message.sqlite"),momdBundle: mondBundle)
        if let updater = self.coreDataUpdater
        {
            updater.update(userId)
        }
    }
    
    
    fileprivate func initDocumentUrl(_ userId:String)
    {
        documentsPathUrl = PersistentManager.sharedInstance.rootUrl.appendingPathComponent(userId)
        PersistentManager.sharedInstance.createDir(documentsPathUrl)
    }
    
    fileprivate func initLocalStoreDir()
    {
        localStorePathUrl = documentsPathUrl.appendingPathComponent("localStore")
        PersistentManager.sharedInstance.initFileDir(localStorePathUrl)
    }

    fileprivate var fetchingLock = NSRecursiveLock()
    func setFetching(_ fileId:String)
    {
        fetchingLock.lock()
        self.fetchingIdMap[fileId] = "true"
        fetchingLock.unlock()
    }
    
    func fetchingFinished(_ fileId:String)
    {
        fetchingLock.lock()
        self.fetchingIdMap.removeValue(forKey: fileId)
        fetchingLock.unlock()
    }
    
    func isFetching(_ fileId:String) -> Bool
    {
        fetchingLock.lock()
        let flag = fetchingIdMap.keys.contains(fileId)
        fetchingLock.unlock()
        return flag
    }
    
    func getFilePath(_ fileId:String!,type:FileType!) -> String!
    {
        if let path = PersistentManager.sharedInstance.getFilePathFromCachePath(fileId, type: type)
        {
            return path
        }else
        {
            return PersistentManager.sharedInstance.getStorageFileEntity(fileId)?.getObsoluteFilePath() ?? nil
        }
    }
    
    func removeFile(_ fileId:String,type:FileType) -> Bool {
        if PersistentManager.sharedInstance.deleteStorageFileEntityAndFile(fileId){
            return true
        }else if let path = PersistentManager.sharedInstance.getFilePathFromCachePath(fileId, type: type)
        {
            return PersistentFileHelper.deleteFile(path)
        }else{
            return false
        }
    }
    
    fileprivate func createLocalStoreDirPathOfFileType(_ fileType:FileType) -> String
    {
        return createLocalStoreDirUrlOfFileType(fileType).path
    }
    
    fileprivate func createLocalStoreDirUrlOfFileType(_ fileType:FileType) -> URL
    {
        return localStorePathUrl.appendingPathComponent("\(fileType.rawValue)")
    }
    
    func createLocalStoreFileName(_ fileType:FileType) -> String
    {
        return createLocalStoreDirUrlOfFileType(fileType).appendingPathComponent("\(PersistentFileHelper.generateTmpFileName())\(fileType.FileSuffix)").path
    }
    
    func getLocalStoreDirFileURLs(_ fileType:FileType) -> [URL]
    {
        let dirURL = createLocalStoreDirUrlOfFileType(fileType)
        do{
            let files = try fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            return files
        }catch
        {
            return [URL]()
        }
    }
    
    func getLocalStoreDirFiles(_ fileType:FileType) -> [String]
    {
        return getLocalStoreDirFileURLs(fileType).map({ (url) -> String in
            return url.path
        })
    }

}

