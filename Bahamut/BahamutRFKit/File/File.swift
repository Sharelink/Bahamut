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

public class FileAccessInfoList : BahamutObject
{
    var files:[FileAccessInfo]!
}

public class FileAccessInfo : BahamutObject
{
    public override func getObjectUniqueIdName() -> String {
        return "fileId"
    }
    public var fileId:String! //the unique id
    public var server:String!
    public var accessKey:String! //local use this as Id
    public var bucket:String!
    public var expireAt:String!
    public var serverType:String!
}

public class SendFileResult : BahamutObject
{
    public var isFinished:Bool!
    public var message:String!
}


