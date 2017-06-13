//
//  AdManager+Vungle.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/23.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

////Install framework with podfile: pod 'VungleSDK-iOS'
//Import h file in Bridge Header: #import <VungleSDK/VungleSDK.h>

extension AdManager{
    static var domainVungle:String{ return "Vungle" }
    
    func configureVungle() {
        VungleSDK.shared().start(withAppId: AdConfig.adConfigDict["Vungle"] as! String)
    }
    
    func playVungleAdVideo(controller:UIViewController) -> Bool {
        do {
            
            try VungleSDK.shared().playAd(controller)
        } catch {
            return false
        }
        return true
    }
}
