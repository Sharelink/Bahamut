//
//  FileType.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
public enum FileType : Int
{
    case Raw = 0
    case NoType = 126
    case Other = 127
    case Text = 128
    case Sound = 129
    case Video = 130
    case Image = 131
    
    static let allValues = [Raw, NoType, Other, Text, Sound, Video, Image]
    
    var FileSuffix:String
        {
            return FileType.getFileTypeFileSuffix(self)
    }
    
    static func getFileTypeFileSuffix(type:FileType) -> String
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
    
    static func getFileType(rawValue:Int) -> FileType
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
    
    static func getFileTypeByFileId(fileId:String) -> FileType
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
