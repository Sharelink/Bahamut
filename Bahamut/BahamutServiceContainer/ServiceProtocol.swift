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
    @objc optional func appStartInit(_ appName:String)
    @objc optional func userLoginInit(_ userId:String)
    @objc optional func userLogout(_ userId:String)
}

typealias ServiceListDict = [(String,ServiceProtocol)]
