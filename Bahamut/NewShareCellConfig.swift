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
    
    static var numberOfNewShareCellType:Int{
        return CellConfig.count
    }
    
    static let CellConfig =
    [
        (cellReuseId:"NewShareFilmCell",headerTitle:NSLocalizedString("SHARE_HEADER_TITLE_VIDEO", comment: ""),headerImg:"videoHeader"),
        (cellReuseId:"NewShareTextCell",headerTitle:NSLocalizedString("SHARE_HEADER_TITLE_TEXT", comment: ""),headerImg:"textHeader"),
        (cellReuseId:"NewShareUrlCell",headerTitle:NSLocalizedString("SHARE_HEADER_TITLE_LINK", comment: ""),headerImg:"urlHeader")
    ]
}