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

    func fetchBahamutFire(_ fireInfo:FileAccessInfo,fileType:FileType, progress:@escaping (_ fid:String,_ persent:Float)->Void, callback:@escaping (_ fid:String,_ filePath:String?) -> Void)
    {
        let absoluteFilePath = PersistentManager.sharedInstance.createCacheFileName(fireInfo.fileId, fileType: fileType)
        let tmpFilePath = PersistentManager.sharedInstance.createTmpFileName(fileType)
        
        let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
        client.downloadFile(fireInfo.accessKey,filePath: tmpFilePath).downloadProgress(closure: { (progressObj) in
            progress(fireInfo.fileId, Float(progressObj.fractionCompleted * 100.0))
        }).response { (response) in
            self.fetchingFinished(fireInfo.fileId)
            
            if response.response != nil && response.response!.statusCode == 200 && PersistentFileHelper.fileSizeOf(tmpFilePath) > 0
            {
                PersistentFileHelper.moveFile(tmpFilePath, destinationPath: absoluteFilePath)
                callback(fireInfo.fileId, absoluteFilePath)
            }else
            {
                PersistentFileHelper.deleteFile(tmpFilePath)
                callback(fireInfo.fileId, nil)
            }
        }
    }
}

