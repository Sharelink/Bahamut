//
//  CommonExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import AVFoundation

func isInSimulator() -> Bool{
    return TARGET_IPHONE_SIMULATOR == Int32("1")
}

func isHeadPhoneInserted(includeBluetooth:Bool = true) -> Bool {
    for desc in AVAudioSession.sharedInstance().currentRoute.outputs{
        var ports = [AVAudioSessionPortHeadphones]
        if includeBluetooth {
            ports.append(contentsOf: [AVAudioSessionPortBluetoothLE,AVAudioSessionPortBluetoothA2DP,AVAudioSessionPortBluetoothHFP])
        }
        return ports.contains(desc.portType)
    }
    return false
}

//4s Or Older
func isSmallScreenDevice() -> Bool{
    let size = UIScreen.main.bounds
    return max(size.width, size.height) < 568
}

func isIPadDevice() -> Bool {
    return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
}

func isIPhoneDevice() -> Bool {
    return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
}

class VersionReader {
    static var appVersion:String{
        if let infoDic = Bundle.main.infoDictionary
        {
            let version = infoDic["CFBundleShortVersionString"] as! String
            return version
        }
        return "1.0"
    }
    
    static var buildVersion:Int{
        if let infoDic = Bundle.main.infoDictionary
        {
            let version = infoDic["CFBundleVersion"] as! String
            return Int(version) ?? 1
        }
        return 1
    }
}
