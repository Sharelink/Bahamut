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
        playSound(1011)
    }
    
    static func keyTink()
    {
        playSound(1103)
    }
    
    static func keyTock()
    {
        playSound(1105)
    }
    
    static func cameraShutter()
    {
        playSound(1108)
    }
    
    static func playSound(_ systemSoundId:SystemSoundID)
    {
        AudioServicesPlaySystemSound(systemSoundId)
    }
    
    static func playSound(_ url:URL){
        let id = createAudio(url)
        playSound(id)
    }
    
    static func createAudio(_ url:URL) -> SystemSoundID{
        var id:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &id)
        return id
    }
}
