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
