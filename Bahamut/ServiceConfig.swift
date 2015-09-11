//
//  ServiceConfig.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

struct ServiceConfig
{
    static let Services:[String:ServiceProtocol] =
    [
        AccountService.ServiceName:AccountService(),
        ReplyService.ServiceName:ReplyService(),
        ShareService.ServiceName:ShareService(),
        UserService.ServiceName:UserService(),
        FileService.ServiceName:FileService(),
        UserTagService.ServiceName:UserTagService()
    ]
}