//
//  Math.swift
//  Vessage
//
//  Created by Alex Chow on 2016/10/22.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
class Math {
    static func distanceOf2Points(p1:CGPoint,p2:CGPoint) -> Double{
        return sqrt(pow(Double(p1.x) - Double(p2.x), 2) - pow(Double(p1.y) - Double(p2.y), 2))
    }
}
