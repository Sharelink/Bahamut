//
//  Integer+FriendlyString.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

func intToBadgeString(value:Int!) -> String?{
    if value == nil {
        return nil
    }
    if value <= 0 {
        return nil
    }
    if value > 99 {
        return "99+"
    }
    return "\(value)"
}

extension Int64{
    var friendString:String{
        if self >= 1000 {
            return "\(self / 1000)k"
        }
        return "\(self)"
    }
}

extension Int32{
    var friendString:String{
        if self >= 1000 {
            return "\(self / 1000)k"
        }
        return "\(self)"
    }
}

extension Int{
    var friendString:String{
        if self >= 1000 {
            return "\(self / 1000)k"
        }
        return "\(self)"
    }
}
