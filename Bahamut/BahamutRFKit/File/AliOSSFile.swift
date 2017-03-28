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
open class NewAliOSSFileAccessInfoRequest : BahamutRFRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/AliOSSFiles"
        self.method = .post
    }
    
    open override func getMaxRequestCount() -> Int32 {
        return BahamutRFRequestBase.maxRequestNoLimitCount
    }
    
    open var fileType:FileType! = .noType{
        didSet{
            self.paramenters["fileType"] = "\(fileType!.rawValue)"
        }
    }
    
    open var fileSize:Int = 512 * 1024{ //byte
        didSet{
            self.paramenters["fileSize"] = "\(fileSize)"
        }
    }
}

/*
POST /AliOSSFiles/List (fileTypes,fileSizes) : get a new send files key for upload task
*/
open class NewAliOSSFileAccessInfoListRequest : BahamutRFRequestBase
{
    public override init()
    {
        super.init()
        self.api = "/AliOSSFiles/List"
        self.method = .post
    }
    
    open var fileTypes:[FileType]!{
        didSet{
            if fileTypes != nil && fileTypes.count > 0
            {
                self.paramenters["fileTypes"] = fileTypes.map{"\($0.rawValue)"}.joined(separator: "#")
            }
        }
    }
    
    open var fileSizes:[Int]!{ //byte
        didSet{
            if fileSizes != nil && fileSizes.count > 0
            {
                self.paramenters["fileSizes"] = fileSizes.map{"\($0)"}.joined(separator: "#")
            }
        }
    }
    
    open override func getMaxRequestCount() -> Int32 {
        return BahamutRFRequestBase.maxRequestNoLimitCount
    }
}
