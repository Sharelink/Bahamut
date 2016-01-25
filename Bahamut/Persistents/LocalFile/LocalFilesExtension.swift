//
//  LocalFilesExtension.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/8.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: FilePersistents

class LocalFileExtensionConstant
{
    static let fileEntityName = "FileInfoEntity"
    static let fileEntityIdFieldName = "fileId"
    static let uploadTaskEntityName = "UploadTask"
    static let uploadTaskEntityIdFieldName = "fileId"
    
    static let coreDataModelId = "BahamutLocalFile"
}

extension FileInfoEntity
{
    func getObsoluteFilePath() -> String!
    {
        return PersistentManager.sharedInstance.getAbsoluteFilePath(self.localPath)
    }
}

class LocalFilesExtension: PersistentExtensionProtocol
{
    static var defaultInstance:LocalFilesExtension!
    private(set) var coreData = CoreDataManager()
    private(set) var fileCacheDirUrl:NSURL!
    
    func initFileCacheDir(documentUrl:NSURL)
    {
        fileCacheDirUrl = documentUrl.URLByAppendingPathComponent("caches")
        PersistentManager.sharedInstance.initFileDir(fileCacheDirUrl)
    }
    
    func clearFileCacheDir()
    {
        PersistentFileHelper.deleteFile(LocalFilesExtension.defaultInstance.fileCacheDirUrl.path!)
        PersistentManager.sharedInstance.initFileDir(LocalFilesExtension.defaultInstance.fileCacheDirUrl)
    }
    
    func releaseExtension() {
        LocalFilesExtension.defaultInstance = nil
        coreData.deinitManager()
    }
    
    func destroyExtension() {
        coreData.destroyDbFile()
    }
    
    func resetExtension() {
    }
    
    func storeImmediately() {
        coreData.saveNow()
    }
}

extension PersistentManager
{
    
    func useLocalFilesExtension(dbFileUrl:NSURL,documentDirUrl:NSURL,momdBundle:NSBundle){
        self.useExtension(LocalFilesExtension()) { (ext) -> Void in
            LocalFilesExtension.defaultInstance = ext
            let cdmid = LocalFileExtensionConstant.coreDataModelId
            ext.coreData.initManager(cdmid, dbFileUrl:dbFileUrl,momdBundle: momdBundle)
            ext.initFileCacheDir(documentDirUrl)
        }
    }
    
    func clearFileCacheFiles()
    {
        LocalFilesExtension.defaultInstance.clearFileCacheDir()
    }
    
    func deleteStorageFile(fileId:String)
    {
        if let entity = getStorageFileEntity(fileId)
        {
            let filePath = entity.getObsoluteFilePath()
            LocalFilesExtension.defaultInstance.coreData.deleteObject(entity)
            PersistentFileHelper.deleteFile(filePath)
        }
    }
    
    func bindFileIdAndPath(fileId:String,data:NSData, filePath:String) -> FileInfoEntity?
    {
        if PersistentFileHelper.storeFile(data, filePath: filePath)
        {
            return bindFileIdAndPath(fileId, fileExistsPath: filePath)
        }else
        {
            return nil
        }
    }
    
    func bindFileIdAndPath(fileId:String,fileExistsPath:String) -> FileInfoEntity?
    {
        var relativePath:String!
        if let index = fileExistsPath.rangeOfString(rootUrl.path!)?.last
        {
            let i = index.advancedBy(2) //advance 2 to trim '/' operator
            relativePath = fileExistsPath.substringFromIndex(i)
        }else
        {
            relativePath = fileExistsPath
        }
        let absolutePath = rootUrl.URLByAppendingPathComponent(relativePath).path!
        if NSFileManager.defaultManager().fileExistsAtPath(absolutePath)
        {
            if let fileEntity = getStorageFileEntity(fileId)
            {
                fileEntity.localPath = relativePath
                LocalFilesExtension.defaultInstance.coreData.saveNow()
                return fileEntity
            }else if let fileEntity = LocalFilesExtension.defaultInstance.coreData.insertNewCell(LocalFileExtensionConstant.fileEntityName) as? FileInfoEntity
            {
                fileEntity.localPath = relativePath
                fileEntity.fileId = fileId
                LocalFilesExtension.defaultInstance.coreData.saveNow()
                return fileEntity
            }
        }
        return nil
    }

    func getStorageFileEntity(fileId:String!) -> FileInfoEntity?
    {
        if fileId == nil || fileId.isEmpty
        {
            return nil
        }
        let cache = getCache(LocalFileExtensionConstant.fileEntityName)
        if let fileEntity = cache.objectForKey(fileId) as? FileInfoEntity
        {
            return fileEntity
        }else if let fileEntity = LocalFilesExtension.defaultInstance.coreData.getCellById(LocalFileExtensionConstant.fileEntityName,
            idFieldName: LocalFileExtensionConstant.fileEntityIdFieldName, idValue: fileId) as? FileInfoEntity
        {
            return fileEntity
        }else
        {
            return nil
        }
    }
    
    func createCacheFileName(fileId:String,fileType:FileType) -> String
    {
        let localStoreFileDir = LocalFilesExtension.defaultInstance.fileCacheDirUrl.URLByAppendingPathComponent("\(fileType.rawValue)")
        let fileName = "\(fileId)\(fileType.FileSuffix)"
        return localStoreFileDir.URLByAppendingPathComponent(fileName).path!
    }
    
    func getFilePathFromCachePath(fileId:String,type:FileType!) -> String!
    {
        let path = createCacheFileName(fileId,fileType: type)
        if NSFileManager.defaultManager().fileExistsAtPath(path)
        {
            return path
        }
        return nil
    }
    
    func getImageFilePath(fileId:String?) -> String!
    {
        if fileId == nil
        {
            return nil
        }
        if let path = getFilePathFromCachePath(fileId!, type: FileType.Image)
        {
            return path
        }else if let entify = getStorageFileEntity(fileId)
        {
            return getAbsoluteFilePath(entify.localPath)
        }
        return nil
    }
    
    func getImage(fileId:String?) -> UIImage?
    {
        if fileId == nil
        {
            return nil
        }
        let cache = getCache("UIImage")
        if let image = cache.objectForKey(fileId!) as? UIImage
        {
            return image
        }else if let image = UIImage(named: fileId!)
        {
            cache.setObject(image, forKey: fileId!)
            return image
        }else if let path = getImageFilePath(fileId)
        {
            if let image = UIImage(contentsOfFile: path)
            {
                cache.setObject(image, forKey: fileId!)
                return image
            }
        }
        return nil
    }
}
