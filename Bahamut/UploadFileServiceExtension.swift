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
    
    func initFileUploadProc()
    {
        
    }
    
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
    
    func requestFileId(localfilePath:String,type:FileType,callback:(fileId:String!) -> Void)
    {
        let req = NewSendFileKeyRequest()
        do{
            let fileSize = try fileManager.attributesOfItemAtPath(localfilePath)[NSFileSize] as! Int
            req.fileSize = fileSize
        }catch{
            
        }
        let client = ShareLinkSDK.sharedInstance.getFileClient()
        req.fileType = type
        
        client.execute(req) { (result:SLResult<SendFileKey>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                if let sendFileKey = result.returnObject
                {
                    let fileAccesskey = sendFileKey.accessKey
                    let fileServer = sendFileKey.acceptServerUrl
                    if let uploadTask = self.addUploadTask(fileAccesskey,filePath: localfilePath)
                    {
                        uploadTask.fileId = fileAccesskey
                        uploadTask.fileServerUrl = fileServer
                        uploadTask.status = SendFileStatus.SendFileReady
                        if let _ = PersistentManager.sharedInstance.saveFile(fileAccesskey,fileExistsPath: localfilePath)
                        {
                            callback(fileId: fileAccesskey)
                            return
                        }else
                        {
                            CoreDataHelper.deleteObject(uploadTask)
                        }
                    }
                    
                }
            }
            callback(fileId: nil)
        }
    }
    
    func startSendFile(fileId:String)
    {
        let uploadTask = getUploadTask(fileId)
        let sendFileKey = SendFileKey()
        sendFileKey.acceptServerUrl = uploadTask.fileServerUrl
        sendFileKey.accessKey = uploadTask.fileId
        let client = ShareLinkSDK.sharedInstance.getFileClient()

        func progressCallback(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            let persent = Float( bytesRead / totalBytesRead)
            UploadTaskWatcher.sharedInstance.setProgress(fileId, persent: persent)
        }
        
        let _ = client.sendFile(sendFileKey, filePath: uploadTask.localPath).progress(progressCallback).responseJSON{ (_, _, JSON) -> Void in
            if JSON.error == nil
            {
                UploadTaskWatcher.sharedInstance.setUploadCompleted(fileId)
                CoreDataHelper.deleteObject(uploadTask)
            }else
            {
                UploadTaskWatcher.sharedInstance.setUploadFailed(fileId)
            }
        }
    }
    
}

class UploadTaskWatcher : NSObject
{
    static let sharedInstance:UploadTaskWatcher = {
        return UploadTaskWatcher()
    }()
    
    
    func addUploadTaskObserver(fileId:String,delegate:FileUploadDelegate)
    {

    }
    
    func removeUploadTaskObserver(fileId:String,delegate:FileUploadDelegate)
    {
        
    }
    
    func setProgress(fileId:String,persent:Float)
    {
        
    }
    
    func setUploadCompleted(fileId:String)
    {
        
    }
    
    func setUploadFailed(fileId:String)
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