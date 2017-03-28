//
//  File.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/4.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

open class FileAccessInfoList : BahamutObject
{
    var files:[FileAccessInfo]!
}

open class FileAccessInfo : BahamutObject
{
    open override func getObjectUniqueIdName() -> String {
        return "fileId"
    }
    open var fileId:String! //the unique id
    open var server:String!
    open var accessKey:String! //local use this as Id
    open var bucket:String!
    open var expireAt:String!
    open var serverType:String!
}

open class SendFileResult : BahamutObject
{
    open var isFinished:Bool!
    open var message:String!
}


