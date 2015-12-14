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
    @objc static var ServiceName:String{return "NotificationService"}
    
    private(set) var isMute:Bool = true
    private(set) var openVibration:Bool = true
    private var userId:String!
    
    @objc func appStartInit()
    {
        setMute(false)
        setVibration(false)
    }
    
    @objc func userLoginInit(userId: String)
    {
        isMute = NSUserDefaults.standardUserDefaults().boolForKey("\(userId):isMute")
        openVibration = NSUserDefaults.standardUserDefaults().boolForKey("\(userId):openVibration")
        self.userId = userId
        self.setServiceReady()
    }
    
    func setMute(isMute:Bool)
    {
        NSUserDefaults.standardUserDefaults().setBool(isMute, forKey: "\(userId):isMute")
        self.isMute = isMute
    }
    
    func setVibration(isOpen:Bool)
    {
        NSUserDefaults.standardUserDefaults().setBool(isOpen, forKey: "\(userId):openVibration")
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