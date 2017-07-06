//
//  Math.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

class Math {
    static func distanceOf2Points(_ p1:CGPoint,p2:CGPoint) -> CGFloat{
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
}

func random() -> Int {
    return NSNumber(value: arc4random() as UInt32).intValue
}

func debugLog(_ format: String, _ args: CVarArg...) {
    #if DEBUG
        print("\(Date().toAccurateDateTimeString()): \(String(format: format, arguments: args))")
    #endif
}
