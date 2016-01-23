//
//  UploadFileServiceBaseExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/24.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

struct SendFileStatus
{
    static let UploadTaskReady:NSNumber = 0
    static let SendFileReady:NSNumber = 1
    static let SendingFile:NSNumber = 2
    static let SendFileCompleted:NSNumber = 3
    static let TaskDeleted:NSNumber = 4
    static let RequestFileAccessInfoFailed:NSNumber = 5
}
let FileServiceUploadTask = "FileServiceUploadTask"


extension FileService
{
    func uploadTaskCompleted(taskId:String,fileKey:FileAccessInfo,isSuc:Bool)
    {
        if isSuc
        {
            let uploadTask = self.getUploadTask(fileKey.fileId)
            LocalFilesExtension.defaultInstance.coreData.deleteObject(uploadTask)
            ProgressTaskWatcher.sharedInstance.missionCompleted(taskId, result: FileServiceUploadTask)
        }else
        {
            ProgressTaskWatcher.sharedInstance.missionFailed(taskId, result: FileServiceUploadTask)
        }
    }
    
    func prepareUpload(localFilePath:String,req:ShareLinkSDKRequestBase,callback:(taskId:String!,fileKey:FileAccessInfo!)->Void)
    {
        self.requestFileAccessInfo(req, callback: { (fileKey) -> Void in
            if fileKey != nil
            {
                if let uploadTask = self.addUploadTask(fileKey, filePath: localFilePath)
                {
                    let taskKey = "uploadTask:\(uploadTask.fileId)"
                    callback(taskId: taskKey, fileKey: fileKey)
                    return
                }
                
            }
            callback(taskId: nil, fileKey: nil)
        })
    }
    
    private func getUploadTask(fileId:String) -> UploadTask!
    {
        if let uploadTask = LocalFilesExtension.defaultInstance.coreData.getCellById(LocalFileExtensionConstant.uploadTaskEntityName, idFieldName: LocalFileExtensionConstant.uploadTaskEntityIdFieldName, idValue: fileId) as? UploadTask
        {
            return uploadTask
        }
        return nil
    }
    
    private func addUploadTask(sendFileKey:FileAccessInfo,filePath:String) -> UploadTask?
    {
        if !fileManager.fileExistsAtPath(filePath)
        {
            return nil
        }
        if let _ = PersistentManager.sharedInstance.bindFileIdAndPath(sendFileKey.accessKey,fileExistsPath: filePath)
        {
            let uploadTask = LocalFilesExtension.defaultInstance.coreData.insertNewCell(LocalFileExtensionConstant.uploadTaskEntityName) as! UploadTask
            uploadTask.status = SendFileStatus.UploadTaskReady
            uploadTask.localPath = filePath
            uploadTask.fileId = sendFileKey.fileId
            uploadTask.fileServerUrl = sendFileKey.server
            LocalFilesExtension.defaultInstance.coreData.saveNow()
            return uploadTask
        }
        return nil
    }

}