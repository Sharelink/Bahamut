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
    
    func getFileFetcherOfFileId(fileType:FileType) -> FileFetcher
    {
        let fetcher = IdFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
    
    func fetchBahamutFire(fireInfo:FileAccessInfo,fileType:FileType,callback:(filePath:String!) -> Void)
    {
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fireInfo.fileId, fileType: fileType)
        let tmpFilePath = PersistentManager.sharedInstance.createTmpFileName(fileType)
        
        func progress(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            ProgressTaskWatcher.sharedInstance.setProgress(fireInfo.fileId, persent: Float(totalBytesRead * 100 / totalBytesExpectedToRead))
        }
        let client = SharelinkSDK.sharedInstance.getBahamutFireClient()
        client.downloadFile(fireInfo.accessKey,filePath: tmpFilePath).progress(progress).response{ (request, response, result, error) -> Void in
            self.fetchingFinished(fireInfo.fileId)
            if error == nil && response?.statusCode == ReturnCode.OK.rawValue && PersistentManager.sharedInstance.fileSizeOf(tmpFilePath) > 0
            {
                PersistentManager.sharedInstance.moveFile(tmpFilePath, destinationPath: absoluteFilePath)
                callback(filePath:absoluteFilePath)
                ProgressTaskWatcher.sharedInstance.missionCompleted(fireInfo.fileId, result: absoluteFilePath)
            }else
            {
                PersistentManager.sharedInstance.deleteFile(tmpFilePath)
                callback(filePath:nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(fireInfo.fileId, result: nil)
            }
        }
    }
}

