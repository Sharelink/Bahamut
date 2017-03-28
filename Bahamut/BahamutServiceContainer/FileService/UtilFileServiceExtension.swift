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
    func requestFileAccessInfo(_ req:BahamutRFRequestBase,callback:@escaping (_ fileKey:FileAccessInfo?) -> Void)
    {
        let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
        client.execute(req) { (result:SLResult<FileAccessInfo>) -> Void in
            if result.isSuccess
            {
                if let fileAccessInfo = result.returnObject
                {
                    fileAccessInfo.saveModel()
                    callback(fileAccessInfo)
                    return
                }
            }
            callback(nil)
        }
    }
    
    func requestFileAccessInfoList(_ req:BahamutRFRequestBase,callback:@escaping (_ fileKeys:[FileAccessInfo]?) -> Void)
    {
        let client = BahamutRFKit.sharedInstance.getBahamutFireClient()
        client.execute(req) { (result:SLResult<FileAccessInfoList>) -> Void in
            if result.isSuccess
            {
                if let list = result.returnObject
                {
                    FileAccessInfo.saveObjectOfArray(list.files)
                    callback(list.files)
                    return
                }
            }
            callback(nil)
        }
    }
    
}
