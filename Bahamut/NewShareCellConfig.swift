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
        (shareType:ShareThingType.shareFilm,cellReuseId:"NewShareFilmCell",headerTitle:NSLocalizedString("SHARE_HEADER_TITLE_VIDEO", comment: ""),headerImg:"videoHeader"),
        (shareType:ShareThingType.shareText,cellReuseId:"NewShareTextCell",headerTitle:NSLocalizedString("SHARE_HEADER_TITLE_TEXT", comment: ""),headerImg:"textHeader"),
        (shareType:ShareThingType.shareUrl,cellReuseId:"NewShareUrlCell",headerTitle:NSLocalizedString("SHARE_HEADER_TITLE_LINK", comment: ""),headerImg:"urlHeader")
    ]
}