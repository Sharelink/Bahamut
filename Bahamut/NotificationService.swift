//
//  NotificationService.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/29.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import AudioToolbox

class NotificationService: ServiceProtocol
{
    static let vibrationEnableKey = "vibrationEnable"
    static let isMuteKey = "isMute"
    
    @objc static var ServiceName:String{return "NotificationService"}
    
    private(set) var isMute:Bool = true
    private(set) var openVibration:Bool = true
    private var userId:String!
    
    @objc func appStartInit()
    {
    }
    
    @objc func userLoginInit(userId: String)
    {
        openVibration = UserSetting.isSettingEnable(NotificationService.vibrationEnableKey)
        isMute = UserSetting.isSettingEnable(NotificationService.isMuteKey)
        self.userId = userId
        self.setServiceReady()
    }
    
    func setMute(isMute:Bool)
    {
        UserSetting.setSetting(NotificationService.isMuteKey, enable: isMute)
        self.isMute = isMute
    }
    
    func setVibration(isOpen:Bool)
    {
        UserSetting.setSetting(NotificationService.vibrationEnableKey, enable: isOpen)
        openVibration = isOpen
    }
    
    func playReceivedMessageSound()
    {
        if self.isMute == false
        {
            AudioServicesPlayAlertSound(1007)
        }
    }
    
    func playHintSound()
    {
        if self.isMute == false
        {
            AudioServicesPlayAlertSound(1000)
        }
    }
}