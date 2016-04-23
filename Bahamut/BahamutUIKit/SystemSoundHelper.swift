//
//  SystemSoundHelper.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/7.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import AudioToolbox

class SystemSoundHelper
{
    static func vibrate()
    {
        AudioServicesPlaySystemSound(1011)
    }
    
    static func keyTink()
    {
        AudioServicesPlaySystemSound(1103)
    }
    
    static func keyTock()
    {
        AudioServicesPlaySystemSound(1105)
    }
    
    static func cameraShutter()
    {
        AudioServicesPlayAlertSound(1108)
    }
    
    static func playSound(systemSoundId:SystemSoundID)
    {
        AudioServicesPlaySystemSound(systemSoundId)
    }
}