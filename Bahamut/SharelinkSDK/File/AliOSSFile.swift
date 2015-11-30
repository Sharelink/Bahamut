//
//  AliOSSFile.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/25.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

/*
POST /AliOSSFiles (fileType,fileSize) : get a new send file key for upload task
*/
public class NewAliOSSFileAccessInfoRequest : ShareLinkSDKRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/AliOSSFiles"
        self.method = .POST
    }
    
    public var fileType:FileType! = .NoType{
        didSet{
            self.paramenters["fileType"] = "\(fileType.rawValue)"
        }
    }
    
    public var fileSize:Int = 512 * 1024{ //byte
        didSet{
            self.paramenters["fileSize"] = "\(fileSize)"
        }
    }
}