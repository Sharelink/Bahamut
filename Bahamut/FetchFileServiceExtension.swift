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
        let client = ShareLinkSDK.sharedInstance.getFileClient()
        
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fileId, fileType: fileType)
        
        func progress(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            print("bytesRead:\(bytesRead) , totalBytesRead:\(totalBytesRead) , totalBytesExpectedToRead:\(totalBytesExpectedToRead)")
            ProgressTaskWatcher.sharedInstance.setProgress(fileId, persent: Float(totalBytesRead * 100 / totalBytesExpectedToRead))
        }
        
        client.downloadFile(fileId,filePath: absoluteFilePath).progress(progress).response{ (request, response, result, error) -> Void in
            if error == nil
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
        let fileService = ServiceContainer.getService(FileService)
        if let path = fileService.getFilePath(fileId, type: fileType){
            print("\(fileId) already exists")
            delegate.taskCompleted(fileId, result: path)
        }else
        {
            print("downloading \(fileId)")
            ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: delegate)
            fileService.fetch(fileId, fileType: fileType, callback: { (filePath) -> Void in
                ProgressTaskWatcher.sharedInstance.removeTaskObserver(fileId, delegate: delegate)
            })
        }
        
    }
}

class FilePathFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(filepath: String, delegate: ProgressTaskDelegate) {
        delegate.taskCompleted(filepath, result: filepath)
    }
    
    static let shareInstance:FileFetcher = {
        return FilePathFileFetcher()
        }()
}
