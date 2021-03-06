//
//  AdManager+Vungle.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/23.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

//Install framework with podfile: pod 'VungleSDK-iOS' #Need 5.0 or later
//Import h file in Bridge Header: #import <VungleSDK/VungleSDK.h>
private var vunglePlacements:[String]!
extension AdManager{
    static var domainVungle:String{ return "Vungle" }
    
    func configureVungle() {
        if let vungleDict = AdConfig.adConfigDict["Vungle"] as? NSDictionary{
            if let vid = vungleDict.value(forKey: "vungleId") as? String,let placements = vungleDict.value(forKey: "placements") as? [String]{
                vunglePlacements = placements
                do{
                    try VungleSDK.shared().start(withAppId: vid, placements: placements)
                }catch let err{
                    debugPrint("Configure Vungle Error:\(err)")
                }
            }
        }
    }
    
    func playVungleAdVideo(controller:UIViewController,placementIndex:Int = 0) -> Bool{
        if vunglePlacements != nil && vunglePlacements.count > placementIndex{
            return playVungleAdVideo(controller: controller, placement: vunglePlacements[placementIndex])
        }else{
            return playVungleAdVideo(controller: controller, placement: nil)
        }
    }
    
    func playVungleAdVideo(controller:UIViewController,placement:String?) -> Bool {
        if !VungleSDK.shared().isInitialized{
            return false
        }else if let pid = placement {
            if VungleSDK.shared().isAdCached(forPlacementID: pid){
                do {
                    try VungleSDK.shared().playAd(controller, placementID: placement)
                    return true
                } catch let err{
                    debugPrint("Play Vungle Ad Error:\(err)")
                }
            }
        }
        
        do{
            try VungleSDK.shared().playAd(controller, options: nil, placementID: nil)
            return true
        }catch let err{
            debugPrint("Play Vungle Ad Error:\(err)")
        }
        return false
    }
}
