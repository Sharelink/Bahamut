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
        documentsPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first as! String)
        documentsPathUrl = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL
        uploadQueue = [UploadTask]()
        initFileUploadProc()
    }
    
    struct Constrants
    {
        static let FileEntityName = "FileRelationshipEntity"
        static let FileEntityIdFieldName = "fileId"
        static let UploadTaskEntityName = "UploadTask"
        static let UploadTaskEntityIdFieldName = "taskId"
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
        let uploadTask = CoreDataHelper.insertNewCell(Constrants.UploadTaskEntityName) as! UploadTask
        uploadTask.status = SendFileStatus.UploadTaskReady
        uploadTask.taskId = "\(type.rawValue)_\(NSDate().description)"
        uploadTask.localPath = filePath
        uploadTask.fileType = type.rawValue
        CoreDataHelper.getEntityContext().save(nil)
        return uploadTask.taskId
    }
    
    func requestSendFileKey(uploadTaskId:String,type:FileType,callback:((sendFileRequest:Request) -> Void)! = nil)
    {
        let uploadTask = CoreDataHelper.getCellById(Constrants.UploadTaskEntityName, idFieldName: Constrants.UploadTaskEntityIdFieldName, idValue: uploadTaskId) as! UploadTask
        let filePath = uploadTask.localPath
        let fileSize = fileManager.attributesOfItemAtPath(filePath, error: nil)?[NSFileSize] as! Int
        let client = ShareLinkSDK.sharedInstance.getFileClient() as! FileClient
        let req = NewSendFileKeyRequest()
        req.fileSize = fileSize
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
                    let fileEntity = CoreDataHelper.insertNewCell(Constrants.FileEntityName) as! FileRelationshipEntity
                    fileEntity.filePath = filePath
                    fileEntity.fileId = fileAccesskey
                    fileEntity.fileServerUrl = fileServer
                    CoreDataHelper.getEntityContext().save(nil)
                    if let returnRequest:((Request) -> Void) = callback
                    {
                        let req = client.sendFile(sendFileKey, filePath: filePath, fileType: type).responseJSON{ (_, _, JSON, err) -> Void in
                            if err == nil
                            {
                                uploadTask.status = SendFileStatus.SendFileCompleted
                                
                            }
                        }
                        
                        returnRequest(req)
                    }
                }
            }
            uploadTask.status = SendFileStatus.RequestSendFileKeyFailed
            CoreDataHelper.getEntityContext().save(nil)
        })
    }

    func fetch(fileId:String,fetchCompleted:(filePath:String)->Void,progressUpdate:((bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)->Void)! = nil)
    {
        let client = ShareLinkSDK.sharedInstance.getFileClient() as! FileClient
        let req = client.downloadFile(fileId).progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
            if let progressCallback = progressUpdate
            {
                progressCallback(bytesRead: bytesRead, totalBytesRead: totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
            }
        }.response { (request, _, _, err) -> Void in
            if err == nil
            {
                let fileEntity = CoreDataHelper.insertNewCell(Constrants.FileEntityName) as! FileRelationshipEntity
                fileEntity.fileId = fileId
                fileEntity.filePath = self.documentsPathUrl!.URLByAppendingPathComponent("files/\(fileId)").path!
                CoreDataHelper.getEntityContext().save(nil)
                fetchCompleted(filePath: fileEntity.filePath)
            }else
            {
                fetchCompleted(filePath: "defaultHeadIcon")
            }
            
        }
    }
    
    func getFile(fileId:String,returnCallback:(filePath:String)->Void,progress:((persent:Float)->Void)! = nil)
    {
        if let fileEntity = CoreDataHelper.getCellById(Constrants.FileEntityName, idFieldName: Constrants.FileEntityIdFieldName, idValue: fileId) as? FileRelationshipEntity
        {
            returnCallback(filePath: fileEntity.filePath)
        }else
        {
            if progress == nil
            {
                fetch(fileId, fetchCompleted: returnCallback)
            }else{
                fetch(fileId, fetchCompleted: returnCallback, progressUpdate: { (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
                    let persent = Float( bytesRead / totalBytesRead)
                    progress(persent:persent)
                })
            }
        }
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