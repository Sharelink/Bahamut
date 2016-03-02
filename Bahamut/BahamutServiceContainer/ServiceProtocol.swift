//
//  ServiceProtocol.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

@objc
protocol ServiceProtocol
{
    static var ServiceName:String {get}
    optional func appStartInit(appName:String)
    optional func userLoginInit(userId:String)
    optional func userLogout(userId:String)
}

typealias ServiceListDict = [(String,ServiceProtocol)]