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
    fileprivate func sendBahamutFire(_ localFilePath:String,type:FileType,callback:@escaping (_ taskId:String,_ fileKey:FileAccessInfo?)->Void)
    {
        if let req = generateBahamutFireFileIdReq(localFilePath, type: type)
        {
            self.prepareUpload(localFilePath, req: req, callback: { (taskId, fileKey) -> Void in
                if let tid = taskId,let fk = fileKey
                {
                    callback(tid, fk)
                    let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
                    func progressCallback(progress:Progress)
                    {
                        ProgressTaskWatcher.sharedInstance.setProgress(tid, persent: Float(100.0 * progress.fractionCompleted))
                    }
                    client.sendFile(fk, filePath: localFilePath).uploadProgress(closure: progressCallback).responseJSON(completionHandler: { (response) in
                        self.uploadTaskCompleted(tid, fileKey: fk, isSuc: response.result.isSuccess)
                    })

                }else
                {
                    let failTaskId = IdUtil.generateUniqueId()
                    callback(failTaskId, nil)
                    ProgressTaskWatcher.sharedInstance.missionFailed(failTaskId, result: FileServiceUploadTask)
                }
                
            })
        }
    }
    
    fileprivate func generateBahamutFireFileIdReq(_ localfilePath:String,type:FileType) -> BahamutRFRequestBase!
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
