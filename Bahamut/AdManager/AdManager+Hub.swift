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
    @discardableResult
    func playVideoAd(vc:UIViewController, adIndex:Int = -1) -> Bool {
        let switchAd = adIndex >= 0 ? adIndex : videoAdTimes
        
        let played = (switchAd % 2 == 0) ? (AdManager.shared.playVungleAdVideo(controller: vc) || AdManager.shared.playGADRewardAd(controller: vc)) :
            (AdManager.shared.playGADRewardAd(controller: vc) || AdManager.shared.playVungleAdVideo(controller: vc))
        if played{
            videoAdTimes += 1
        }
        return played
    }
}

extension AdManager{
    @discardableResult
    func showInterstitialAd(vc:UIViewController,adIndex:Int = -1) -> Bool {
        let switchAd = adIndex >= 0 ? adIndex : interstitialAdTimes
        
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
