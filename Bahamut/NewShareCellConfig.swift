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
    
    static let CellConfig =
    [
        (shareType:ShareThingType.shareFilm,cellReuseId:NewShareFilmCell.reuseableId,headerTitleLocalizedKey:"SHARE_HEADER_TITLE_VIDEO"),
        (shareType:ShareThingType.shareText,cellReuseId:NewShareTextCell.reuseableId,headerTitleLocalizedKey:"SHARE_HEADER_TITLE_TEXT"),
        (shareType:ShareThingType.shareImage,cellReuseId:NewShareImageCell.reuseableId,headerTitleLocalizedKey:"SHARE_HEADER_TITLE_IMAGE"),
        (shareType:ShareThingType.shareUrl,cellReuseId:NewShareUrlCell.reuseableId,headerTitleLocalizedKey:"SHARE_HEADER_TITLE_LINK")
    ]
}