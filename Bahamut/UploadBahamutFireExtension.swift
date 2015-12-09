//
//  UploadFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

extension FileService
{
    private func sendBahamutFire(localFilePath:String,type:FileType,callback:(taskId:String,fileKey:FileAccessInfo!)->Void)
    {
        if let req = generateBahamutFireFileIdReq(localFilePath, type: type)
        {
            self.prepareUpload(localFilePath, req: req, callback: { (taskId, fileKey) -> Void in
                if taskId != nil
                {
                    callback(taskId: taskId, fileKey: fileKey)
                    let client = SharelinkSDK.sharedInstance.getBahamutFireClient()
                    func progressCallback(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
                    {
                        let persent = Float( totalBytesRead * 100 / totalBytesExpectedToRead)
                        ProgressTaskWatcher.sharedInstance.setProgress(taskId, persent: persent)
                    }
                    
                    client.sendFile(fileKey, filePath: localFilePath).progress(progressCallback).responseJSON { (response) -> Void in
                        self.uploadTaskCompleted(taskId, fileKey: fileKey, isSuc: response.result.isSuccess)
                    }

                }else
                {
                    let failTaskId = IdUtil.generateUniqueId()
                    callback(taskId: failTaskId, fileKey: nil)
                    ProgressTaskWatcher.sharedInstance.missionFailed(failTaskId, result: FileServiceUploadTask)
                }
                
            })
        }
    }
    
    private func generateBahamutFireFileIdReq(localfilePath:String,type:FileType) -> ShareLinkSDKRequestBase!
    {
        let req = NewBahamutFireRequest()
        let fileSize = PersistentFileHelper.fileSizeOf(localfilePath)
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
