//
//  FetchAliOSSExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/25.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

extension FileAccessInfo
{
    func isServerTypeAliOss() -> Bool
    {
        if let st = self.serverType
        {
            return "alioss" == st
        }
        return false
    }
}

extension FileService
{
    
    func fetchFromAliOSS(fileAccessInfo:FileAccessInfo,fileType:FileType,callback:(filePath:String!) -> Void)
    {
        let bucket = fileAccessInfo.bucket
        let objkey = fileAccessInfo.fileId
        let server = fileAccessInfo.server
        let fileId = fileAccessInfo.fileId
        func progress(persent:Float)
        {
            ProgressTaskWatcher.sharedInstance.setProgress(fileId, persent: persent)
        }
        
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fileId, fileType: fileType)
        let tmpFilePath = PersistentManager.sharedInstance.createTmpFileName(fileType)
        
        AliOSSManager.sharedInstance.download(server,bucket: bucket, objkey: objkey, filePath: tmpFilePath, progress: progress) { (isSuc, task) -> Void in
            self.fetchingFinished(fileId)
            if isSuc
            {
                PersistentFileHelper.moveFile(tmpFilePath, destinationPath: absoluteFilePath)
                callback(filePath:absoluteFilePath)
                ProgressTaskWatcher.sharedInstance.missionCompleted(fileId, result: absoluteFilePath)
            }else
            {
                PersistentFileHelper.deleteFile(tmpFilePath)
                callback(filePath:nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(fileId, result: nil)
            }
        }
    }
}