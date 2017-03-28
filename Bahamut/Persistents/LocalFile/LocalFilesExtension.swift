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
    
    static let coreDataModelId:String = "BahamutLocalFile"
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
    fileprivate(set) var coreData = CoreDataManager()
    fileprivate(set) var fileCacheDirUrl:URL!
    
    func initFileCacheDir(_ documentUrl:URL)
    {
        fileCacheDirUrl = documentUrl.appendingPathComponent("caches")
        PersistentManager.sharedInstance.initFileDir(fileCacheDirUrl)
    }
    
    func clearFileCacheDir()
    {
        PersistentFileHelper.deleteFile(LocalFilesExtension.defaultInstance.fileCacheDirUrl.path)
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
    
    func useLocalFilesExtension(_ dbFileUrl:URL,documentDirUrl:URL,momdBundle:Bundle){
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
    
    func bindFileIdAndPath(_ fileId:String,data:Data, filePath:String) -> FileInfoEntity?
    {
        if PersistentFileHelper.storeFile(data, filePath: filePath)
        {
            return bindFileIdAndPath(fileId, fileExistsPath: filePath)
        }else
        {
            return nil
        }
    }
    
    func bindFileIdAndPath(_ fileId:String,fileExistsPath:String) -> FileInfoEntity?
    {
        var relativePath:String!
        
        if let index = fileExistsPath.range(of: rootUrl.path)?.upperBound
        {
            let i = fileExistsPath.index(index, offsetBy: 1) //Trim charater /
            relativePath = fileExistsPath.substring(from: i)
        }else
        {
            relativePath = fileExistsPath
        }
        let absolutePath = rootUrl.appendingPathComponent(relativePath).path
        if FileManager.default.fileExists(atPath: absolutePath)
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

    func getStorageFileEntity(_ fileId:String!) -> FileInfoEntity?
    {
        if fileId == nil || fileId.isEmpty
        {
            return nil
        }
        if let fileEntity = LocalFilesExtension.defaultInstance.coreData.getCellById(LocalFileExtensionConstant.fileEntityName,
            idFieldName: LocalFileExtensionConstant.fileEntityIdFieldName, idValue: fileId) as? FileInfoEntity
        {
            return fileEntity
        }else
        {
            return nil
        }
    }
    
    func deleteStorageFileEntityAndFile(_ fileId:String) -> Bool {
        var deleted = false
        if let fe = getStorageFileEntity(fileId) {
            if let path = fe.getObsoluteFilePath(){
                PersistentFileHelper.deleteFile(path)
                deleted = true
            }
            LocalFilesExtension.defaultInstance.coreData.deleteObject(fe)
        }
        return deleted
    }
    
    func createCacheFileName(_ fileId:String,fileType:FileType) -> String
    {
        let localStoreFileDir = LocalFilesExtension.defaultInstance.fileCacheDirUrl.appendingPathComponent("\(fileType.rawValue)")
        let fileName = "\(fileId)\(fileType.FileSuffix)"
        return localStoreFileDir.appendingPathComponent(fileName).path
    }
    
    func getFilePathFromCachePath(_ fileId:String,type:FileType!) -> String!
    {
        let path = createCacheFileName(fileId,fileType: type)
        if FileManager.default.fileExists(atPath: path)
        {
            return path
        }
        return nil
    }
    
    func getImageFilePath(_ fileId:String?) -> String!
    {
        if fileId == nil
        {
            return nil
        }
        if let path = getFilePathFromCachePath(fileId!, type: FileType.image)
        {
            return path
        }else if let entify = getStorageFileEntity(fileId)
        {
            return getAbsoluteFilePath(entify.localPath)
        }
        return nil
    }
    
    func getImage(_ fileId:String?,bundle:Bundle? = Bundle.main) -> UIImage?
    {
        if String.isNullOrWhiteSpace(fileId) {
            return nil
        }
        let fid = fileId!
        let typeName = "UIImage"
        if let image = getCachedModel(typeName, modelId: fid) as? UIImage
        {
            return image
        }else if let image = UIImage(named: fid,in: bundle,compatibleWith:nil)
        {
            cacheModel(typeName, modelId: fid, model: image)
            return image
        }else if let path = getImageFilePath(fid)
        {
            if let image = UIImage(contentsOfFile: path)
            {
                cacheModel(typeName, modelId: fid, model: image)
                return image
            }
        }
        return nil
    }
}
