//
//  NewShareImageCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
class NewShareImageCell: ShareContentCellBase
{
    static let reuseableId = "NewShareImageCell"
    
    override func getCellHeight() -> CGFloat {
        return 128
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        return true
    }
}