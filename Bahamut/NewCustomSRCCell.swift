//
//  NewCustomSRCCell.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/19.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import UIKit

class NewCustomSRCCell: ShareContentCellBase
{
    static let reuseableId = "NewCustomSRCCell"
    
    @IBOutlet weak var srcNameLabel: UILabel!
    
    @IBOutlet weak var srcWebView: UIWebView!
    
    override func getCellHeight() -> CGFloat {
        return 200
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        return true
    }
}
