//
//  UploadFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import Alamofire

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
    
    func requestFileId(localfilePath:String,type:FileType,callback:(fileKey:SendFileKey!) -> Void)
    {
        let req = NewSendFileKeyRequest()
        do{
            let fileSize = try fileManager.attributesOfItemAtPath(localfilePath)[NSFileSize] as! Int
            req.fileSize = fileSize
        }catch let err as NSError{
            print(err)
            callback(fileKey: nil)
            return
        }
        let client = ShareLinkSDK.sharedInstance.getFileClient()
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
    
    func startSendFile(accessKey:String)
    {
        let uploadTask = getUploadTask(accessKey)
        let sendFileKey = SendFileKey()
        sendFileKey.server = uploadTask.fileServerUrl
        sendFileKey.accessKey = uploadTask.fileId
        let client = ShareLinkSDK.sharedInstance.getFileClient()

        func progressCallback(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            let persent = Float( totalBytesRead * 100 / totalBytesExpectedToRead)
            ProgressTaskWatcher.sharedInstance.setProgress(accessKey, persent: persent)
        }
        
        client.sendFile(sendFileKey, filePath: uploadTask.localPath).progress(progressCallback).responseJSON{ (request, _, JSON) -> Void in
            if JSON.error == nil
            {
                ProgressTaskWatcher.sharedInstance.missionCompleted(accessKey, result: accessKey)
                CoreDataHelper.deleteObject(uploadTask)
            }else
            {
                ProgressTaskWatcher.sharedInstance.missionFailed(accessKey, result: accessKey)
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