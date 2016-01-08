//
//  NewShareCellConfig.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/13.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
class NewShareCellConfig
{

    static func indexOfReuseId(cellReuseId:String) -> Int?{
        return CellConfig.indexOf{$0.cellReuseId == cellReuseId}
    }
    
    static func indexOfShareType(type:ShareThingType?) -> Int?{
        if type == nil
        {
            return nil
        }
        return CellConfig.indexOf{$0.shareType == type}
    }
    
    static var numberOfNewShareCellType:Int{
        return CellConfig.count
    }
    
    static func configOfIndex(index:Int!) -> (shareType:ShareThingType,cellReuseId:String,headerTitle:String,viewTitle:String)?
    {
        if index != nil && index >= 0 && index < CellConfig.count
        {
            return CellConfig[index]
        }
        return nil
    }
    
    static func configOfReuseId(cellReuseId:String) -> (shareType:ShareThingType,cellReuseId:String,headerTitle:String,viewTitle:String)?
    {
        return configOfIndex(indexOfReuseId(cellReuseId))
    }
    
    static func configOfShareType(type:ShareThingType?) -> (shareType:ShareThingType,cellReuseId:String,headerTitle:String,viewTitle:String)?
    {
        return configOfIndex(indexOfShareType(type))
    }
    
    private static let CellConfig =
    [
        (shareType:ShareThingType.shareFilm,cellReuseId:NewShareFilmCell.reuseableId,headerTitle:"SHARE_HEADER_TITLE_VIDEO",viewTitle:"SHARE_VIEW_TITLE_NEW_FILM"),
        (shareType:ShareThingType.shareText,cellReuseId:NewShareTextCell.reuseableId,headerTitle:"SHARE_HEADER_TITLE_TEXT",viewTitle:"SHARE_VIEW_TITLE_NEW_TEXT"),
        (shareType:ShareThingType.shareImage,cellReuseId:NewShareImageCell.reuseableId,headerTitle:"SHARE_HEADER_TITLE_IMAGE",viewTitle:"SHARE_VIEW_TITLE_NEW_IMAGE"),
        (shareType:ShareThingType.shareUrl,cellReuseId:NewShareUrlCell.reuseableId,headerTitle:"SHARE_HEADER_TITLE_LINK",viewTitle:"SHARE_VIEW_TITLE_NEW_URL")
    ]
}