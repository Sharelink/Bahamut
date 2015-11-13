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
    
    private(set) var openSound:Bool = true
    private(set) var openVibration:Bool = true
    private var userId:String!
    
    @objc func appStartInit()
    {
        setMute(false)
        setVibration(false)
    }
    
    @objc func userLoginInit(userId: String)
    {
        openSound = NSUserDefaults.standardUserDefaults().boolForKey("\(userId):openSound")
        openVibration = NSUserDefaults.standardUserDefaults().boolForKey("\(userId):openVibration")
        self.userId = userId
    }
    
    func setMute(isMute:Bool)
    {
        NSUserDefaults.standardUserDefaults().setBool(isMute, forKey: "\(userId):openSound")
        openSound = !isMute
    }
    
    func setVibration(isOpen:Bool)
    {
        NSUserDefaults.standardUserDefaults().setBool(isOpen, forKey: "\(userId):openVibration")
        openVibration = isOpen
    }
    
    func playVibration()
    {
        AudioServicesPlayAlertSound(1011)
    }
    
    func playReceivedMessageSound()
    {
        if openSound
        {
            AudioServicesPlayAlertSound(1007)
        }
    }
    
    func playHintSound()
    {
        if openSound
        {
            AudioServicesPlayAlertSound(1000)
        }
    }
}