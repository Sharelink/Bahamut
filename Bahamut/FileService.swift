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
    @objc func initService() {
        fileManager = NSFileManager.defaultManager()
        documentsPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first)
        documentsPathUrl = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        initFileDir()
        uploadQueue = [UploadTask]()
        initFileUploadProc()
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
    
    private var uploadQueue:[UploadTask]!
    private var fileManager:NSFileManager!
    private var documentsPath:String!
    private var documentsPathUrl:NSURL!
    
    func addSendFileTask(filePath:String,type:FileType) -> String!
    {
        if !fileManager.fileExistsAtPath(filePath)
        {
            return nil
        }
        let uploadTask = CoreDataHelper.insertNewCell(FilePersistentsConstrants.UploadTaskEntityName) as! UploadTask
        uploadTask.status = SendFileStatus.UploadTaskReady
        uploadTask.taskId = "\(type.rawValue)_\(NSDate().description)"
        uploadTask.localPath = filePath
        uploadTask.fileType = type.rawValue
        uploadTask.saveModified()
        return uploadTask.taskId
    }
    
    func requestSendFileKey(uploadTaskId:String,type:FileType,callback:((sendFileRequest:Request) -> Void)! = nil)
    {
        let uploadTask = CoreDataHelper.getCellById(FilePersistentsConstrants.UploadTaskEntityName, idFieldName: FilePersistentsConstrants.UploadTaskEntityIdFieldName, idValue: uploadTaskId) as! UploadTask
        let filePath = uploadTask.localPath
        let req = NewSendFileKeyRequest()
        do{
            let fileSize = try fileManager.attributesOfItemAtPath(filePath)[NSFileSize] as! Int
            req.fileSize = fileSize
        }catch{
            
        }
        let client = ShareLinkSDK.sharedInstance.getFileClient() as! FileClient
        req.fileType = type
        
        client.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                if let sendFileKey = result as? SendFileKey
                {
                    let fileAccesskey = sendFileKey.fileId
                    let fileServer = sendFileKey.fileServer
                    uploadTask.accessKey = fileAccesskey
                    uploadTask.fileId = fileAccesskey
                    uploadTask.fileServerUrl = fileServer
                    uploadTask.status = SendFileStatus.SendFileReady
                    if let fileEntity:FileRelationshipEntity = PersistentManager.sharedInstance.saveFile(filePath)
                    {
                        fileEntity.filePath = filePath
                        fileEntity.fileId = fileAccesskey
                        fileEntity.fileServerUrl = fileServer
                        fileEntity.saveModified()
                        if let returnRequest:((Request) -> Void) = callback
                        {
                            let req = client.sendFile(sendFileKey, filePath: filePath, fileType: type).responseJSON{ (_, _, JSON) -> Void in
                                if JSON.error == nil
                                {
                                    CoreDataHelper.deleteObject(uploadTask)
                                }
                            }
                            returnRequest(req)
                        }
                    }
                    return
                }
            }
            uploadTask.status = SendFileStatus.RequestSendFileKeyFailed
            uploadTask.saveModified()
        })
    }

    func fetch(fileId:String,fileType:FileType,fetchCompleted:(filePath:String)->Void,progressUpdate:((bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)->Void)! = nil)
    {
        let client = ShareLinkSDK.sharedInstance.getFileClient() as! FileClient
        let filePath = self.documentsPathUrl!.URLByAppendingPathComponent("\(fileType.rawValue)/\(fileId)").path!
        client.downloadFile(fileId,filePath: filePath).progress ({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
            if let progressCallback = progressUpdate
            {
                progressCallback(bytesRead: bytesRead, totalBytesRead: totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
            }
        }).responseString { (request, response, result) -> Void in
            if result.error == nil
            {
                
                if let fileEntity = PersistentManager.sharedInstance.saveFile(filePath)
                {
                    fileEntity.fileId = fileId
                    fileEntity.saveModified()
                    fetchCompleted(filePath: fileEntity.filePath)
                }
            }else
            {
                fetchCompleted(filePath: "defaultHeadIcon")
            }
        }
    }
    
    func getFile(fileId:String,returnCallback:(filePath:String)->Void,progress:((persent:Float)->Void)! = nil)
    {
        if let fileEntity = PersistentManager.sharedInstance.getFile(fileId)
        {
            returnCallback(filePath: fileEntity.filePath)
        }else
        {
            let fileType = FileType.getFileTypeByFileId(fileId)
            if progress == nil
            {
                fetch(fileId,fileType:fileType, fetchCompleted: returnCallback)
            }else{
                fetch(fileId,fileType:fileType, fetchCompleted: returnCallback, progressUpdate: { (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
                    let persent = Float( bytesRead / totalBytesRead)
                    progress(persent:persent)
                })
            }
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
    
    func initFileUploadProc()
    {
        
    }
}

public struct SendFileStatus
{
    static let UploadTaskReady:NSNumber = 0
    static let SendFileReady:NSNumber = 1
    static let SendingFile:NSNumber = 2
    static let SendFileCompleted:NSNumber = 3
    static let TaskDeleted:NSNumber = 4
    static let RequestSendFileKeyFailed:NSNumber = 5
}