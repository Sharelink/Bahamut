//
//  AliOSSFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/24.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: FileService Extension
extension FileService
{
    func initAliOSSManager()
    {
        AliOSSManager.sharedInstance.initManager()
    }
    
    func sendFileToAliOSS(localFilePath:String,type:FileType,callback:(taskId:String,fileKey:FileAccessInfo!)->Void)
    {
        self.prepareUpload(localFilePath, req: generateAliOSSUploadRequest(localFilePath, type: type)) { (taskId, fileKey) -> Void in
            if fileKey != nil
            {
                callback(taskId: taskId, fileKey: fileKey)
                
                AliOSSManager.sharedInstance.upload(fileKey.server,bucket: fileKey.bucket, objkey: fileKey.fileId, filePath: localFilePath, progress: { (persent) -> Void in
                    ProgressTaskWatcher.sharedInstance.setProgress(taskId, persent: persent)
                    }, taskCompleted: { (isSuc) -> Void in
                        self.uploadTaskCompleted(taskId, fileKey: fileKey, isSuc: isSuc)
                })
            }else{
                let failTaskId = IdUtil.generateUniqueId()
                callback(taskId: failTaskId, fileKey: nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(failTaskId, result: FileServiceUploadTask)
            }
        }
    }
    
    private func generateAliOSSUploadRequest(localfilePath:String,type:FileType) -> ShareLinkSDKRequestBase!
    {
        let req = NewAliOSSFileAccessInfoRequest()
        let fileSize = PersistentManager.sharedInstance.fileSizeOf(localfilePath)
        if fileSize > 0
        {
            req.fileSize = fileSize
            req.fileType = type
            return req
        }else
        {
            return nil
        }
    }
}