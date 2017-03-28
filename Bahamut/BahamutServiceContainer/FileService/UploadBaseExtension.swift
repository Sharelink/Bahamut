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
    func uploadTaskCompleted(_ taskId:String,fileKey:FileAccessInfo,isSuc:Bool)
    {
        if isSuc,let uploadTask = self.getUploadTask(fileKey.fileId)
        {
            
            LocalFilesExtension.defaultInstance.coreData.deleteObject(uploadTask)
            ProgressTaskWatcher.sharedInstance.missionCompleted(taskId, result: FileServiceUploadTask)
        }else
        {
            ProgressTaskWatcher.sharedInstance.missionFailed(taskId, result: FileServiceUploadTask)
        }
    }
    
    func prepareUpload(_ localFilePath:String,req:BahamutRFRequestBase,callback:@escaping (_ taskId:String?,_ fileKey:FileAccessInfo?)->Void)
    {
        self.requestFileAccessInfo(req, callback: { (fileKey) -> Void in
            if let fk = fileKey
            {
                if let uploadTask = self.addUploadTask(fk, filePath: localFilePath)
                {
                    let taskKey = "uploadTask:\(uploadTask.fileId)"
                    callback(taskKey, fileKey)
                    return
                }
                
            }
            callback(nil, nil)
        })
    }
    
    fileprivate func getUploadTask(_ fileId:String) -> UploadTask!
    {
        if let uploadTask = LocalFilesExtension.defaultInstance.coreData.getCellById(LocalFileExtensionConstant.uploadTaskEntityName, idFieldName: LocalFileExtensionConstant.uploadTaskEntityIdFieldName, idValue: fileId) as? UploadTask
        {
            return uploadTask
        }
        return nil
    }
    
    fileprivate func addUploadTask(_ sendFileKey:FileAccessInfo,filePath:String) -> UploadTask?
    {
        if !fileManager.fileExists(atPath: filePath)
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
