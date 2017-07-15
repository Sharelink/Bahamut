//
//  AdManager+VideoManager.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/30.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
private var videoAdTimes = 0
private var interstitialAdTimes = 0

extension AdManager{
    func playVideoAd(vc:UIViewController, times:Int = -1) -> Bool {
        let switchAd = times >= 0 ? times : videoAdTimes
        
        let played = (switchAd % 2 == 0) ? (AdManager.shared.playVungleAdVideo(controller: vc) || AdManager.shared.playGADRewardAd(controller: vc)) :
            (AdManager.shared.playGADRewardAd(controller: vc) || AdManager.shared.playVungleAdVideo(controller: vc))
        if played{
            videoAdTimes += 1
        }
        return played
    }
}

extension AdManager{
    func showInterstitialAd(vc:UIViewController,times:Int = -1) -> Bool {
        let switchAd = times >= 0 ? times : interstitialAdTimes
        
        var played = false
        
        if switchAd % 2 == 0 {
            played = AdManager.shared.playGADInterstitial(controller: vc) || AdManager.shared.playFBInterstitialAd(vc: vc) || AdManager.shared.playGDTAdInterstitia(controller: vc)
        }else {
            played = AdManager.shared.playFBInterstitialAd(vc: vc) || AdManager.shared.playGADInterstitial(controller: vc) || AdManager.shared.playGDTAdInterstitia(controller: vc)
        }
        
        if played{
            interstitialAdTimes += 1
        }
        
        return played
    }
}
