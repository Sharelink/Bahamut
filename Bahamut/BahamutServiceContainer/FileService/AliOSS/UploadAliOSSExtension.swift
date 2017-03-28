//
//  AliOSSFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/24.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class UploadFilesTask: BahamutObject
{
    var taskId:String!
    var fileKeys:[FileAccessInfo]!
    var finishFileCount:NSNumber!
}

//MARK: FileService Extension
extension FileService
{
    
//TODO: Not finish function
//    func sendFilesToAliOSS(filePaths:[String],types:[FileType],callback:(taskId:String,fileKeys:[FileAccessInfo]!)->Void)
//    {
//        var reqs = [NewAliOSSFileAccessInfoRequest]()
//        for i in 0..<filePaths.count
//        {
//            let req = generateAliOSSUploadRequest(filePaths[i], type: types[i])
//            reqs.append(req)
//        }
//        
//        let req = NewAliOSSFileAccessInfoListRequest()
//        req.fileSizes = reqs.map{$0.fileSize}
//        req.fileTypes = reqs.map{$0.fileType}
//        
//        self.requestFileAccessInfoList(req, callback: { (fileKeys) -> Void in
//            let taskId = IdUtil.generateUniqueId()
//            let task = UploadFilesTask()
//            task.taskId = "uploadTask:\(taskId)"
//            task.fileKeys = fileKeys
//            task.finishFileCount = 0
//            
//            
//            //MARK: TO DO: finish queue upload
//        })
//    }
    
    func sendFileToAliOSS(_ localFilePath:String,type:FileType,callback:@escaping (_ taskId:String,_ fileKey:FileAccessInfo?)->Void)
    {
        self.prepareUpload(localFilePath, req: generateAliOSSUploadRequest(localFilePath, type: type)) { (taskId, fileKey) -> Void in
            if let fk = fileKey,let tid = taskId
            {
                callback(tid, fk)
                
                AliOSSManager.sharedInstance.upload(fk.server,bucket: fk.bucket, objkey: fk.fileId, filePath: localFilePath, progress: { (persent) -> Void in
                    ProgressTaskWatcher.sharedInstance.setProgress(taskId!, persent: persent)
                    }, taskCompleted: { (isSuc) -> Void in
                        self.uploadTaskCompleted(tid, fileKey: fk, isSuc: isSuc)
                })
            }else{
                let failTaskId = IdUtil.generateUniqueId()
                callback(failTaskId, nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(failTaskId, result: FileServiceUploadTask)
            }
        }
    }
    
    fileprivate func generateAliOSSUploadRequest(_ localfilePath:String,type:FileType) -> NewAliOSSFileAccessInfoRequest!
    {
        let req = NewAliOSSFileAccessInfoRequest()
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
