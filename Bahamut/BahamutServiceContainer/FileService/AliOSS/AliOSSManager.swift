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
    fileprivate var ossClientMap = [String:OSSClient]()
    fileprivate var ossClientConfig:OSSClientConfiguration!
    fileprivate var credential:OSSPlainTextAKSKPairCredentialProvider!
    var openSSL:Bool = false
    func initManager(_ aliOssAccessKey:String, aliOssSecretKey:String)
    {
        let conf = OSSClientConfiguration()
        conf.maxRetryCount = 3
        conf.timeoutIntervalForRequest = 30
        conf.timeoutIntervalForResource = TimeInterval(24 * 60 * 60)
        self.ossClientConfig = conf
        self.credential = OSSPlainTextAKSKPairCredentialProvider(plainTextAccessKey: aliOssAccessKey, secretKey: aliOssSecretKey)
    }
    
    static var sharedInstance:AliOSSManager = {
        return AliOSSManager()
    }()
    
    func getOSSClient(_ endPoint:String) -> OSSClient
    {
        let ep = openSSL ? endPoint.replacingOccurrences(of: "http://", with: "https://", options: .caseInsensitive, range: nil) : endPoint
        if let client  = ossClientMap[ep]
        {
            return client
        }else
        {
            let client = OSSClient(endpoint: ep, credentialProvider: credential,clientConfiguration: self.ossClientConfig)
            ossClientMap[ep] = client
            return client
        }
    }
    
    func upload(_ serverEndpoint:String,bucket:String,objkey:String,filePath:String,progress:@escaping (_ persent:Float)->Void,taskCompleted:@escaping (_ isSuc:Bool)->Void){
        let putReq = OSSPutObjectRequest()
        putReq.uploadingFileURL = URL(fileURLWithPath: filePath)
        upload(serverEndpoint,bucket: bucket,objkey: objkey,req: putReq, progress: progress, taskCompleted: taskCompleted)
    }
    
    func uploadData(_ serverEndpoint:String,bucket:String,objkey:String,data:Data,progress:@escaping (_ persent:Float)->Void,taskCompleted:@escaping (_ isSuc:Bool)->Void){
        let putReq = OSSPutObjectRequest()
        putReq.uploadingData = data
        upload(serverEndpoint,bucket: bucket,objkey: objkey,req: putReq, progress: progress, taskCompleted: taskCompleted)
    }
    
    fileprivate func upload(_ serverEndpoint:String,bucket:String,objkey:String,req:OSSPutObjectRequest,progress:@escaping (_ persent:Float)->Void,taskCompleted:@escaping (_ isSuc:Bool)->Void){
        req.bucketName = bucket
        req.objectKey = objkey
        func uploadProgress(_ bytesSent:Int64, totalByteSent:Int64, totalBytesExpectedToSend:Int64)
        {
            let persent = Float( totalByteSent * 100 / totalBytesExpectedToSend)
            progress(persent)
        }
        let ossClient = getOSSClient(serverEndpoint)
        req.uploadProgress = uploadProgress
        let task = ossClient.putObject(req)
        task.continue({ (task) -> Any? in
            if task.error == nil
            {
                debugLog("OSS File Uploaded")
            }else{
                debugLog("Upload OSS File Failed: %@",task.error?.localizedDescription ?? "Unknow Error")
            }
            taskCompleted(task.error == nil)
            return nil
        })
    }
    
    func getConstrainURL(_ serverEndpoint:String,bucket:String,objkey:String,taskCompleted:@escaping (_ objUrl:String?)->Void)
    {
        let ossClient = getOSSClient(serverEndpoint)
        let task = ossClient.presignConstrainURL(withBucketName: bucket, withObjectKey: objkey, withExpirationInterval: 10 * 60)
        task.continue({ (task) -> Any? in
            if let str = task.result as? NSString{
                taskCompleted(str as String)
            }else{
                taskCompleted(nil)
            }
            return task
        })
    }
    
    func download(_ serverEndpoint:String,bucket:String,objkey:String,filePath:String,progress:@escaping (_ persent:Float)->Void,taskCompleted:@escaping (_ isSuc:Bool,_ task:OSSTask<AnyObject>)->Void)
    {
        let req = OSSGetObjectRequest()
        req.bucketName = bucket
        req.objectKey = objkey
        let tmpFileUrl = PersistentManager.sharedInstance.tmpUrl.appendingPathComponent(PersistentFileHelper.generateTmpFileName())
        req.downloadToFileURL = tmpFileUrl
        func downloadProgress(_ bytesWritten:Int64, totalByteWritten:Int64, totalBytesExpectedToWrite:Int64)
        {
            let persent = Float( totalByteWritten * 100 / totalBytesExpectedToWrite)
            progress(persent)
        }
        req.downloadProgress = downloadProgress
        let ossClient = getOSSClient(serverEndpoint)
        let task = ossClient.getObject(req)
        task.continue({ (task) -> Any? in
            if task.error == nil
            {
                if PersistentFileHelper.moveFile(tmpFileUrl.path, destinationPath: filePath){
                    debugLog("OSS File Fetched")
                    taskCompleted(true, task)
                    return nil
                }
            }
            debugLog("Fetch OSS File Failed")
            taskCompleted(false, task)
            return nil
        })
        
    }
    
}
