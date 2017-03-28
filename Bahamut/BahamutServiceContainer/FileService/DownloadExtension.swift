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
    func startFetch(_ fileId: String, delegate: ProgressTaskDelegate)
    {
        DispatchQueue.global().async { () -> Void in
            if let path = Bundle.main.path(forResource: "\(fileId)", ofType:""){
                if PersistentFileHelper.fileExists(path){
                    delegate.taskCompleted(fileId, result: path)
                }
            }else{
                let fileService = ServiceContainer.getFileService()
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
    
    func getFileFetcherOfFileId(_ fileType:FileType) -> FileFetcher
    {
        let fetcher = IdFileFetcher()
        fetcher.fileType = fileType
        return fetcher
    }
    
}

//MARK: Download FileService Extension
extension FileService
{
    
    func getCachedFileAccessInfo(_ fileId:String)->FileAccessInfo? {
        return PersistentManager.sharedInstance.getModel(FileAccessInfo.self, idValue: fileId)
    }
    
    func fetchFileAccessInfo(_ fileId:String,callback:@escaping (FileAccessInfo?)->Void) {
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

    fileprivate class CallbackTaskDelegate:NSObject,ProgressTaskDelegate {
        var callback:((_ filePath:String?) -> Void)?

        @objc func taskCompleted(_ taskIdentifier:String,result:Any!){
            callback?(result as? String)
        }

        @objc func taskFailed(_ taskIdentifier:String,result:Any!){
            callback?(nil)
        }
    }
    
    
    func fetchFile(_ fileId:String,fileType:FileType,callback:@escaping (_ filePath:String?) -> Void)
    {
        if String.isNullOrWhiteSpace(fileId)
        {
            callback(nil)
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
    
    fileprivate func startFetch(_ fa:FileAccessInfo,fileTyp:FileType)
    {
        func progress(_ fid:String,persent:Float)
        {
            ProgressTaskWatcher.sharedInstance.setProgress(fid, persent: persent)
        }

        func finishCallback(_ fid:String,absoluteFilePath:String?){
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
