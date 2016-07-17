//
//  AliOSSManager.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/25.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import AliyunOSSiOS

//MARK: AliOSSManager
class AliOSSManager
{
    private var ossClientMap = [String:OSSClient]()
    private var ossClientConfig:OSSClientConfiguration!
    private var credential:OSSPlainTextAKSKPairCredentialProvider!
    func initManager(aliOssAccessKey:String, aliOssSecretKey:String)
    {
        let conf = OSSClientConfiguration()
        conf.maxRetryCount = 3
        conf.timeoutIntervalForRequest = 30
        conf.timeoutIntervalForResource = 24 * 60 * 60
        self.ossClientConfig = conf
        self.credential = OSSPlainTextAKSKPairCredentialProvider(plainTextAccessKey: aliOssAccessKey, secretKey: aliOssSecretKey)
    }
    
    static var sharedInstance:AliOSSManager = {
        return AliOSSManager()
    }()
    
    func getOSSClient(endPoint:String) -> OSSClient
    {
        if let client  = ossClientMap[endPoint]
        {
            return client
        }else
        {
            let client = OSSClient(endpoint: endPoint, credentialProvider: credential,clientConfiguration: self.ossClientConfig)
            ossClientMap[endPoint] = client
            return client
        }
    }
    
    func upload(serverEndpoint:String,bucket:String,objkey:String,filePath:String,progress:(persent:Float)->Void,taskCompleted:(isSuc:Bool)->Void){
        let putReq = OSSPutObjectRequest()
        putReq.uploadingFileURL = NSURL(fileURLWithPath: filePath)
        upload(serverEndpoint,bucket: bucket,objkey: objkey,req: putReq, progress: progress, taskCompleted: taskCompleted)
    }
    
    func uploadData(serverEndpoint:String,bucket:String,objkey:String,data:NSData,progress:(persent:Float)->Void,taskCompleted:(isSuc:Bool)->Void){
        let putReq = OSSPutObjectRequest()
        putReq.uploadingData = data
        upload(serverEndpoint,bucket: bucket,objkey: objkey,req: putReq, progress: progress, taskCompleted: taskCompleted)
    }
    
    private func upload(serverEndpoint:String,bucket:String,objkey:String,req:OSSPutObjectRequest,progress:(persent:Float)->Void,taskCompleted:(isSuc:Bool)->Void){
        req.bucketName = bucket
        req.objectKey = objkey
        func uploadProgress(bytesSent:Int64, totalByteSent:Int64, totalBytesExpectedToSend:Int64)
        {
            let persent = Float( totalByteSent * 100 / totalBytesExpectedToSend)
            progress(persent: persent)
        }
        let ossClient = getOSSClient(serverEndpoint)
        req.uploadProgress = uploadProgress
        let task = ossClient.putObject(req)
        task.continueWithBlock { (task) -> AnyObject! in
            if task.error == nil
            {
                NSLog("OSS Upload Success")
            }else{
                NSLog("OSS Upload Failed %@",task.error?.description ?? "Unknow Error")
            }
            taskCompleted(isSuc: task.error == nil)
            return nil
        }
    }
    
    func download(serverEndpoint:String,bucket:String,objkey:String,filePath:String,progress:(persent:Float)->Void,taskCompleted:(isSuc:Bool,task:OSSTask)->Void)
    {
        let req = OSSGetObjectRequest()
        req.bucketName = bucket
        req.objectKey = objkey
        let tmpFileUrl = PersistentManager.sharedInstance.tmpUrl.URLByAppendingPathComponent(PersistentFileHelper.generateTmpFileName())
        req.downloadToFileURL = tmpFileUrl
        func downloadProgress(bytesWritten:Int64, totalByteWritten:Int64, totalBytesExpectedToWrite:Int64)
        {
            let persent = Float( totalByteWritten * 100 / totalBytesExpectedToWrite)
            progress(persent: persent)
        }
        req.downloadProgress = downloadProgress
        let ossClient = getOSSClient(serverEndpoint)
        let task = ossClient.getObject(req)
        task.continueWithBlock { (task) -> AnyObject! in
            if task.error == nil
            {
                if PersistentFileHelper.moveFile(tmpFileUrl.path!, destinationPath: filePath){
                    NSLog("OSS Download Success")
                    taskCompleted(isSuc: true, task: task)
                    return nil
                }
            }
            NSLog("OSS Download Failed")
            taskCompleted(isSuc: false, task: task)
            return nil
        }
    }
    
}
