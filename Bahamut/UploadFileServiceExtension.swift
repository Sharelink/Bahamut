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
    
    private func addSendFileTask(filePath:String,type:FileType) -> String!
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
    
    private func requestSendFileKey(uploadTaskId:String,type:FileType,callback:((sendFileRequest:Request) -> Void)! = nil)
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
        
        client.execute(req) { (result:SLResult<SendFileKey>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                if let sendFileKey = result.returnObject
                {
                    let fileAccesskey = sendFileKey.fileId
                    let fileServer = sendFileKey.fileServer
                    uploadTask.accessKey = fileAccesskey
                    uploadTask.fileId = fileAccesskey
                    uploadTask.fileServerUrl = fileServer
                    uploadTask.status = SendFileStatus.SendFileReady
                    if let fileEntity:FileInfoEntity = PersistentManager.sharedInstance.saveFile(filePath)
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