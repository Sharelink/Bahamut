//
//  IDUtil.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class IdUtil
{
    static func generateUniqueId() -> String
    {
        let code = "\(NSDate().toAccurateDateTimeString())_\(random())"
        return code.md5
    }
}