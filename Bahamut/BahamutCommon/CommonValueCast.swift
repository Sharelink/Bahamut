//
//  CommonValueCast.swift
//  iDiaries
//
//  Created by AlexChow on 16/1/15.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

extension Int
{
    var uIntValue:UInt{
        return UInt(self)
    }
    
    var int32:Int32{
        return Int32(self)
    }
}

extension UInt
{
    var intValue:Int{
        return Int(self)
    }
}