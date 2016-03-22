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
    static var seed:Int = 0
    static let seedLock = NSRecursiveLock()
    static func generateUniqueId() -> String
    {
        seedLock.lock()
        let s = seed + 1
        seed += 1
        if seed == Int.max
        {
            seed = 0
        }
        seedLock.unlock()
        let code = "\(NSDate().toAccurateDateTimeString())_\(s)"
        return code.md5
    }
}