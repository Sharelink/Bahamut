//
//  DownloadBaseExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/25.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: Id File Fetcher
class IdFileFetcher: FileFetcher
{
    var fileType:FileType!;
    func startFetch(fileId: String, delegate: ProgressTaskDelegate)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            if let path = NSBundle.mainBundle().pathForResource("\(fileId)", ofType:""){
                if PersistentFileHelper.fileExists(path){
                    delegate.taskCompleted(fileId, result: path)
                }
            }else{
                let fileService = ServiceContainer.getService(FileService)
                if let path = fileService.getFilePath(fileId, type: self.fileType){
                    delegate.taskCompleted(fileId, result: path)
                }else
                {
                    ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: delegate)
                    fileService.fetchFile(fileId, fileType: self.fileType){ filePath in
                        
                    }
                }
            }
        }
    }
}

extension FileService
{
    
    func getFileFetcherOfFileId(fileType:FileType) -> FileFetcher
    {
        let fetcher = IdFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
    
}

//MARK: Download FileService Extension
extension FileService
{
    
    func getCachedFileAccessInfo(fileId:String)->FileAccessInfo? {
        return PersistentManager.sharedInstance.getModel(FileAccessInfo.self, idValue: fileId)
    }
    
    func fetchFileAccessInfo(fileId:String,callback:(FileAccessInfo?)->Void) {
        let req = GetBahamutFireRequest()
        req.fileId = fileId
        let bahamutFireClient = BahamutRFKit.sharedInstance.getBahamutFireClient()
        bahamutFireClient.execute(req) { (result:SLResult<FileAccessInfo>) -> Void in
            if result.isSuccess{
                if let fa = result.returnObject
                {
                    fa.saveModel()
                    callback(fa)
                    return
                }
            }
            self.fetchingFinished(fileId)
            callback(nil)
        }
    }

    private class CallbackTaskDelegate:NSObject,ProgressTaskDelegate {
        var callback:((filePath:String!) -> Void)?

        @objc func taskCompleted(taskIdentifier:String,result:AnyObject!){
            callback?(filePath:result as? String)
        }

        @objc func taskFailed(taskIdentifier:String,result:AnyObject!){
            callback?(filePath:nil)
        }
    }
    
    
    func fetchFile(fileId:String,fileType:FileType,callback:(filePath:String!) -> Void)
    {
        if String.isNullOrWhiteSpace(fileId)
        {
            callback(filePath: nil)
            return
        }
        let d = CallbackTaskDelegate()
        d.callback = callback    
        ProgressTaskWatcher.sharedInstance.addTaskObserver(fileId, delegate: d)

        if isFetching(fileId)
        {
            return
        }
        setFetching(fileId)
                
        if let fa = getCachedFileAccessInfo(fileId)
        {
            if String.isNullOrWhiteSpace(fa.expireAt) || fa.expireAt.dateTimeOfString.timeIntervalSinceNow > 0
            {
                startFetch(fa,fileTyp: fileType)
                return
            }
        }

        fetchFileAccessInfo(fileId) { (fileAccessInfo) in
            if let fa = fileAccessInfo
            {
                self.startFetch(fa,fileTyp: fileType)
            }else{
                self.fetchingFinished(fileId)
                ProgressTaskWatcher.sharedInstance.missionFailed(fileId, result: nil)
            }
        }
    }
    
    private func startFetch(fa:FileAccessInfo,fileTyp:FileType)
    {
        func progress(fid:String,persent:Float)
        {
            ProgressTaskWatcher.sharedInstance.setProgress(fid, persent: persent)
        }

        func finishCallback(fid:String,absoluteFilePath:String?){
            if String.isNullOrWhiteSpace(absoluteFilePath){
                ProgressTaskWatcher.sharedInstance.missionFailed(fid, result: nil)
            }else{
                ProgressTaskWatcher.sharedInstance.missionCompleted(fid, result: absoluteFilePath)
            }
        }

        if fa.isServerTypeAliOss()
        {
            self.fetchFromAliOSS(fa, fileType: fileTyp, progress:progress, callback: finishCallback)
        }else
        {
            self.fetchBahamutFire(fa, fileType: fileTyp, progress:progress, callback: finishCallback)
        }
    }
}
