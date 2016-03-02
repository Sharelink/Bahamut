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
    static let Services:ServiceListDict =
    [
        (AccountService.ServiceName,AccountService()), //AccountService must be 1st one,it include init SharelinkSetting function
        (FileService.ServiceName,FileService(mondBundle: Sharelink.mainBundle(),coreDataUpdater: UpdateCoreDataHelper())), //FileService must second to init core data
        (ChatService.ServiceName,ChatService()),
        (ShareService.ServiceName,ShareService()),
        (SRCService.ServiceName,SRCService()),
        (UserService.ServiceName,UserService()),
        (SharelinkThemeService.ServiceName,SharelinkThemeService()),
        (NotificationService.ServiceName,NotificationService()),
        (LocationService.ServiceName,LocationService())
    ]
}