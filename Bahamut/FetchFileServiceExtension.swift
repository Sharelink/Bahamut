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
        
        let absoluteFilePath = self.createLocalStoreFileName(fileType)
        
        func progress(bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)
        {
            print("bytesRead:\(bytesRead) : totalBytesRead\(totalBytesRead)")
            ProgressTaskWatcher.sharedInstance.setProgress(fileId, persent: Float(totalBytesRead * 100 / totalBytesExpectedToRead))
        }
        
        client.downloadFile(fileId,filePath: absoluteFilePath).progress(progress).response{ (request, response, result, error) -> Void in
            if error == nil
            {
                if let fe = PersistentManager.sharedInstance.bindFileIdAndPath(fileId,fileExistsPath: absoluteFilePath)
                {
                    ProgressTaskWatcher.sharedInstance.missionCompleted(fileId, result: fe.getObsoluteFilePath())
                    callback(filePath:fe.getObsoluteFilePath())
                    return
                }
            }
            ProgressTaskWatcher.sharedInstance.missionFailed(fileId, result: nil)
            callback(filePath:nil)
        }
    }
}

class IdFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(fileId: String, delegate: ProgressTaskDelegate)
    {
        ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: delegate)
        ServiceContainer.getService(FileService).getFileByFileId(fileId,fileType:fileType) { (filePath) -> Void in
            ProgressTaskWatcher.sharedInstance.removeTaskObserver(fileId, delegate: delegate)
        }
    }
}

class FilePathFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(filepath: String, delegate: ProgressTaskDelegate) {
        delegate.taskCompleted!(filepath, result: filepath)
    }
    
    static let shareInstance:FileFetcher = {
        return FilePathFileFetcher()
        }()
}
