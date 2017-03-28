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
    case raw = 0
    case noType = 126
    case other = 127
    case text = 128
    case sound = 129
    case video = 130
    case image = 131
    
    static let allValues = [raw, noType, other, text, sound, video, image]
    
    var FileSuffix:String
        {
            return FileType.getFileTypeFileSuffix(self)
    }
    
    static func getFileTypeFileSuffix(_ type:FileType) -> String
    {
        switch type
        {
        case .image: return ".png"
        case .noType: return ""
        case .other: return ""
        case .raw: return ".bin"
        case .sound:return ".mp3"
        case .text:return ".txt"
        case .video:return ".mp4"
        }
    }
    
    static func getFileType(_ rawValue:Int) -> FileType
    {
        for type in allValues
        {
            if rawValue == type.rawValue
            {
                return type
            }
        }
        return raw
    }
    
    static func getFileTypeByFileId(_ fileId:String) -> FileType
    {
        for type in allValues
        {
            let fileTypePettern:String =
            "^(*)\(getFileTypeFileSuffix(type))$"
            if fileTypePettern.isRegexMatch(pattern:fileId)
            {
                return type
            }
        }
        return raw
    }
}
