//
//  UtilFileServiceExtension.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit


//MARK: Bahamut Request File Access Info
extension FileService
{
    func requestFileAccessInfo(req:ShareLinkSDKRequestBase,callback:(fileKey:FileAccessInfo!) -> Void)
    {
        let client = SharelinkSDK.sharedInstance.getBahamutFireClient()
        client.execute(req) { (result:SLResult<FileAccessInfo>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                if let fileAccessInfo = result.returnObject
                {
                    fileAccessInfo.saveModel()
                    callback(fileKey: fileAccessInfo)
                    return
                }
            }
            callback(fileKey: nil)
        }
    }
}

//MARK: Set avatar Util
extension FileService
{
    func setAvatar(imageView:UIImageView,iconFileId:String!)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            imageView.image = PersistentManager.sharedInstance.getImage(ImageAssetsConstants.defaultAvatar)
            if let fileId = iconFileId
            {
                if let uiimage =  PersistentManager.sharedInstance.getImage( fileId )
                {
                    imageView.image = uiimage
                }else
                {
                    self.fetchFile(fileId, fileType: FileType.Image, callback: { (filePath) -> Void in
                        if filePath != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                imageView.image = PersistentManager.sharedInstance.getImage(fileId)
                            })
                        }
                    })
                }
            }
        }
    }
}