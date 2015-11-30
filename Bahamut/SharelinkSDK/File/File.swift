//
//  File.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/4.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

public class FileAccessInfo : ShareLinkObject
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

public class SendFileResult : ShareLinkObject
{
    public var isFinished:Bool!
    public var message:String!
}

public enum FileType : Int
{
    case Raw = 0
    case NoType = 126
    case Other = 127
    case Text = 128
    case Sound = 129
    case Video = 130
    case Image = 131
    
    public static let allValues = [Raw, NoType, Other, Text, Sound, Video, Image]
    
    public var FileSuffix:String
    {
        return FileType.getFileTypeFileSuffix(self)
    }
    
    public static func getFileTypeFileSuffix(type:FileType) -> String
    {
        switch type
        {
        case .Image: return ".png"
        case .NoType: return ""
        case .Other: return ""
        case .Raw: return ".bin"
        case .Sound:return ".mp3"
        case .Text:return ".txt"
        case .Video:return ".mp4"
        }
    }
    
    public static func getFileType(rawValue:Int) -> FileType
    {
        for type in allValues
        {
            if rawValue == type.rawValue
            {
                return type
            }
        }
        return Raw
    }
    
    public static func getFileTypeByFileId(fileId:String) -> FileType
    {
        for type in allValues
        {
            let fileTypePettern:String =
            "^(*)\(getFileTypeFileSuffix(type))$"
            if fileTypePettern =~ fileId
            {
                return type
            }
        }
        return Raw
    }
}



