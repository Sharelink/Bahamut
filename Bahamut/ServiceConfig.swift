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
    static let Services:[(String,ServiceProtocol)] =
    [
        (AccountService.ServiceName,AccountService()), //AccountService Must Be First One,it include init SharelinkSetting function
        (FileService.ServiceName,FileService()), //FileService must second to init core data
        (MessageService.ServiceName,MessageService()),
        (ShareService.ServiceName,ShareService()),
        (UserService.ServiceName,UserService()),
        (SharelinkThemeService.ServiceName,SharelinkThemeService()),
        (NotificationService.ServiceName,NotificationService()),
        (LocationService.ServiceName,LocationService())
    ]
}