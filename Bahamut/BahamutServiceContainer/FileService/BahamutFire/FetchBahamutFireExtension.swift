//
//  FetchFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


//MARK: File Service Fetch Extension
extension FileService
{

    func fetchBahamutFire(fireInfo:FileAccessInfo,fileType:FileType, progress:(fid:String,persent:Float)->Void, callback:(fid:String,filePath:String!) -> Void)
    {
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fireInfo.fileId, fileType: fileType)
        let tmpFilePath = PersistentManager.sharedInstance.createTmpFileName(fileType)
        
        func progress(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            let persent = Float(totalBytesRead * 100 / totalBytesExpectedToRead)
            progress(fid:fireInfo.fileId, persent:persent)
        }

        let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
        client.downloadFile(fireInfo.accessKey,filePath: tmpFilePath).progress(progress).response{ (request, response, result, error) -> Void in
            self.fetchingFinished(fireInfo.fileId)
            if error == nil && response?.statusCode == 200 && PersistentFileHelper.fileSizeOf(tmpFilePath) > 0
            {
                PersistentFileHelper.moveFile(tmpFilePath, destinationPath: absoluteFilePath)
                callback(fid:fireInfo.fileId, filePath:absoluteFilePath)
            }else
            {
                PersistentFileHelper.deleteFile(tmpFilePath)
                callback(fid:fireInfo.fileId, filePath:nil)
            }
        }
    }
}

