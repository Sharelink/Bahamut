//
//  DownloadBaseExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/25.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation


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
                fileService.fetchFile(fileId, fileType: self.fileType, callback: { (filePath) -> Void in
                })
            }
        }
        
        
    }
}

extension FileService
{
    func fetchFile(fileId:String,fileType:FileType,callback:(filePath:String!) -> Void)
    {
        if isFetching(fileId)
        {
            return
        }
        setFetching(fileId)
        if let fa = PersistentManager.sharedInstance.getModel(FileAccessInfo.self, idValue: fileId)
        {
            if fa.expireAt == nil || fa.expireAt.dateTimeOfString.timeIntervalSinceNow > 0
            {
                startFetch(fa,fileTyp: fileType,callback: callback)
                return
            }
        }
        let req = GetBahamutFireRequest()
        req.fileId = fileId
        let bahamutFireClient = SharelinkSDK.sharedInstance.getBahamutFireClient()
        bahamutFireClient.execute(req) { (result:SLResult<FileAccessInfo>) -> Void in
            if let fa = result.returnObject
            {
                self.startFetch(fa,fileTyp: fileType,callback: callback)
            }else
            {
                self.fetchingFinished(fileId)
                callback(filePath: nil)
                ProgressTaskWatcher.sharedInstance.missionFailed(fileId, result: nil)
            }
        }
        
    }
    
    private func startFetch(fa:FileAccessInfo,fileTyp:FileType,callback:(filePath:String!) -> Void)
    {
        if "alioss" == fa.type
        {
            self.fetchFromAliOSS(fa, fileType: fileTyp, callback: callback)
        }else
        {
            self.fetchBahamutFire(fa, fileType: fileTyp, callback: callback)
        }
    }
}