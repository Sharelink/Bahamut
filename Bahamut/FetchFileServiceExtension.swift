//
//  FetchFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


extension FileService
{
    
    func getFileFetcherOfFileId(fileType:FileType) -> FileFetcher
    {
        let fetcher = IdFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
    
    func getFileFetcherOfFilePath(fileType:FileType) -> FileFetcher
    {
        let fetcher = FilePathFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
    
    func fetch(fileId:String,fileType:FileType,callback:(filePath:String!) -> Void)
    {
        if isFetching(fileId)
        {
           return
        }
        setFetching(fileId)
        let client = SharelinkSDK.sharedInstance.getFileClient()
        
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fileId, fileType: fileType)
        
        func progress(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            ProgressTaskWatcher.sharedInstance.setProgress(fileId, persent: Float(totalBytesRead * 100 / totalBytesExpectedToRead))
        }
        
        client.downloadFile(fileId,filePath: absoluteFilePath).progress(progress).response{ (request, response, result, error) -> Void in
            self.fetchingFinished(fileId)
            if error == nil && response?.statusCode == ReturnCode.OK.rawValue
            {
                callback(filePath:absoluteFilePath)
                ProgressTaskWatcher.sharedInstance.missionCompleted(fileId, result: absoluteFilePath)
            }else
            {
                callback(filePath:nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(fileId, result: nil)
            }
        }
    }
}

class IdFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(fileId: String, delegate: ProgressTaskDelegate)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let fileService = ServiceContainer.getService(FileService)
            if let path = fileService.getFilePath(fileId, type: self.fileType){
                delegate.taskCompleted(fileId, result: path)
            }else
            {
                ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: delegate)
                fileService.fetch(fileId, fileType: self.fileType, callback: { (filePath) -> Void in
                })
            }
        }
        
        
    }
}

class FilePathFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(filepath: String, delegate: ProgressTaskDelegate) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            delegate.taskCompleted(filepath, result: filepath)
        }
    }
    
    static let shareInstance:FileFetcher = {
        return FilePathFileFetcher()
        }()
}
