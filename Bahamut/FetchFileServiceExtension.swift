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
    
    func getFileFetcher(fileType:FileType) -> FileFetcher
    {
        let fetcher = IdFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
    
    func fetch(fileId:String,fileType:FileType,fetchCompleted:(filePath:String!)->Void,progressUpdate:((bytesRead:Int64, totalBytesRead:Int64, totalBytesExpectedToRead:Int64)->Void)! = nil)
    {
        let client = ShareLinkSDK.sharedInstance.getFileClient() as! FileClient
        let filePath = self.documentsPathUrl!.URLByAppendingPathComponent("\(fileType.rawValue)/\(fileId)").path!
        client.downloadFile(fileId,filePath: filePath).progress ({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
            if let progressCallback = progressUpdate
            {
                progressCallback(bytesRead: bytesRead, totalBytesRead: totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
            }
        }).responseString { (request, response, result) -> Void in
            if result.error == nil
            {
                
                if let fileEntity = PersistentManager.sharedInstance.saveFile(filePath)
                {
                    fileEntity.fileId = fileId
                    fileEntity.saveModified()
                    fetchCompleted(filePath: fileEntity.localPath)
                }
            }else
            {
                fetchCompleted(filePath: nil)
            }
        }
    }
}

class IdFileFetcher: FileFetcher
{
    var fileType:FileType = .Raw
    func startFetch(fileId: String, progress: (persent: Float) -> Void, completed: (filePath: String!) -> Void) {
        ServiceContainer.getService(FileService).getFileByFileId(fileId, returnCallback: completed, progress: progress)
    }
}

class FilePathFileFetcher: FileFetcher
{
    var fileType:FileType = .Raw
    func startFetch(filepath: String, progress: (persent: Float) -> Void, completed: (filePath: String!) -> Void) {
        completed(filePath: filepath)
    }
    
    static let shareInstance:FileFetcher = {
        return FilePathFileFetcher()
        }()
}
