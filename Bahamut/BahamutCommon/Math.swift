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

extension Math{
    static func setFakeRandomSeed(seed:Int) {
        srand48(seed)
    }
    
    static func fakeRandom() -> Double {
        return drand48()
    }
    
    static func fakeIntRandom(max:Int = Int.max) -> Int{
        return Int(drand48() * Double(max))
    }
    
    static func fakeInt64Random(max:Int64 = Int64.max) -> Int64{
        return Int64(drand48() * Double(max))
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
