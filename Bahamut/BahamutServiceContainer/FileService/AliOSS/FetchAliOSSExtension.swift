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
    
    func fetchFromAliOSS(_ fileAccessInfo:FileAccessInfo,fileType:FileType,progress:@escaping (_ fid:String,_ persent:Float)->Void,callback:@escaping (_ fid:String,_ filePath:String?) -> Void)
    {
        let bucket = fileAccessInfo.bucket!
        let objkey = fileAccessInfo.fileId!
        let server = fileAccessInfo.server!
        let fileId = fileAccessInfo.fileId!
        
        func progressCallback(_ persent:Float){
            progress(fileId,persent)
        }
        
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fileId, fileType: fileType)
        let tmpFilePath = PersistentManager.sharedInstance.createTmpFileName(fileType)
        
        AliOSSManager.sharedInstance.download(server,bucket: bucket, objkey: objkey, filePath: tmpFilePath, progress: progressCallback) { (isSuc, task) -> Void in
            self.fetchingFinished(fileId)
            if isSuc
            {
                PersistentFileHelper.moveFile(tmpFilePath, destinationPath: absoluteFilePath)
                callback(fileId, absoluteFilePath)
            }else
            {
                PersistentFileHelper.deleteFile(tmpFilePath)
                callback(fileId, nil)
            }
        }
    }
}
