//
//  UploadFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import Alamofire
import SharelinkSDK


let FileServiceUploadTask = "FileServiceUploadTask"
extension FileService
{
    private func addUploadTask(fileId:String,filePath:String) -> UploadTask?
    {
        if !fileManager.fileExistsAtPath(filePath)
        {
            return nil
        }
        let uploadTask = CoreDataHelper.insertNewCell(FilePersistentsConstrants.uploadTaskEntityName) as! UploadTask
        uploadTask.status = SendFileStatus.UploadTaskReady
        uploadTask.localPath = filePath
        uploadTask.fileId = fileId
        uploadTask.saveModified()
        return uploadTask
    }
    
    private func getUploadTask(fileId:String) -> UploadTask
    {
        let uploadTask = CoreDataHelper.getCellById(FilePersistentsConstrants.uploadTaskEntityName, idFieldName: FilePersistentsConstrants.uploadTaskEntityIdFieldName, idValue: fileId) as! UploadTask
        return uploadTask
    }
    
    func sendFile(localFilePath:String,type:FileType,callback:(taskId:String!,fileKey:SendFileKey!)->Void)
    {
        let taskKey = NSNumber(double: NSDate().timeIntervalSince1970).integerValue.description
        self.requestFileId(localFilePath, type: type, callback: { (fileKey) -> Void in
            if fileKey != nil
            {
                callback(taskId: taskKey, fileKey: fileKey)
                self.startSendFile(fileKey.accessKey,taskKey: taskKey){ suc in
                    if suc
                    {
                        ProgressTaskWatcher.sharedInstance.missionCompleted(taskKey, result: FileServiceUploadTask)
                    }else
                    {
                        ProgressTaskWatcher.sharedInstance.missionFailed(taskKey, result: FileServiceUploadTask)
                    }
                }
            }else
            {
                callback(taskId: nil, fileKey: nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(taskKey, result: FileServiceUploadTask)
            }
        })
    }
    
    private func requestFileId(localfilePath:String,type:FileType,callback:(fileKey:SendFileKey!) -> Void)
    {
        let req = NewSendFileKeyRequest()
        do{
            let fileSize = try fileManager.attributesOfItemAtPath(localfilePath)[NSFileSize] as! Int
            req.fileSize = fileSize
        }catch let err as NSError{
            NSLog(err.description)
            callback(fileKey: nil)
            return
        }
        let client = SharelinkSDK.sharedInstance.getFileClient()
        req.fileType = type
        
        client.execute(req) { (result:SLResult<SendFileKey>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                if let sendFileKey = result.returnObject
                {
                    let fileAccesskey = sendFileKey.accessKey
                    let fileServer = sendFileKey.server
                    if let uploadTask = self.addUploadTask(fileAccesskey,filePath: localfilePath)
                    {
                        uploadTask.fileId = fileAccesskey
                        uploadTask.fileServerUrl = fileServer
                        uploadTask.status = SendFileStatus.SendFileReady
                        if let _ = PersistentManager.sharedInstance.bindFileIdAndPath(fileAccesskey,fileExistsPath: localfilePath)
                        {
                            callback(fileKey: sendFileKey)
                            return
                        }else
                        {
                            CoreDataHelper.deleteObject(uploadTask)
                        }
                    }
                    
                }
            }
            callback(fileKey: nil)
        }
    }
    
    private func startSendFile(accessKey:String,taskKey:String! = nil,fileUploadedCallback:((isSuc:Bool) -> Void)! = nil)
    {
        let uploadTask = getUploadTask(accessKey)
        let sendFileKey = SendFileKey()
        sendFileKey.server = uploadTask.fileServerUrl
        sendFileKey.accessKey = uploadTask.fileId
        let client = SharelinkSDK.sharedInstance.getFileClient()
        let taskIdentifier = taskKey ?? accessKey
        func progressCallback(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            let persent = Float( totalBytesRead * 100 / totalBytesExpectedToRead)
            ProgressTaskWatcher.sharedInstance.setProgress(taskIdentifier, persent: persent)
        }
        
        client.sendFile(sendFileKey, filePath: uploadTask.localPath).progress(progressCallback).responseJSON { (response) -> Void in
            var suc = false
            if response.result.isSuccess
            {
                ProgressTaskWatcher.sharedInstance.missionCompleted(taskIdentifier, result: accessKey)
                CoreDataHelper.deleteObject(uploadTask)
                suc = true
            }else
            {
                ProgressTaskWatcher.sharedInstance.missionFailed(taskIdentifier, result: accessKey)
            }
            if let callback = fileUploadedCallback
            {
                callback(isSuc: suc)
            }
        }
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