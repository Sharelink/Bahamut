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
    func requestFileAccessInfo(req:BahamutRFRequestBase,callback:(fileKey:FileAccessInfo!) -> Void)
    {
        let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
        client.execute(req) { (result:SLResult<FileAccessInfo>) -> Void in
            if result.isSuccess
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
    
    func requestFileAccessInfoList(req:BahamutRFRequestBase,callback:(fileKeys:[FileAccessInfo]!) -> Void)
    {
        let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
        client.execute(req) { (result:SLResult<FileAccessInfoList>) -> Void in
            if result.isSuccess
            {
                if let list = result.returnObject
                {
                    FileAccessInfo.saveObjectOfArray(list.files)
                    callback(fileKeys: list.files)
                    return
                }
            }
            callback(fileKeys: nil)
        }
    }
    
}