//
//  AdManager+VideoManager.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/30.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
extension AdManager{
    func playVideoAd(vc:UIViewController, times:Int) -> Bool {
        if times % 2 == 0 {
            return AdManager.shared.playVungleAdVideo(controller: vc) || AdManager.shared.playGADRewardAd(controller: vc)
        }else{
            return AdManager.shared.playGADRewardAd(controller: vc) || AdManager.shared.playVungleAdVideo(controller: vc)
        }
    }
}

extension AdManager{
    func showInterstitialAd(vc:UIViewController,times:Int) -> Bool {
        if times % 3 == 0 {
            return AdManager.shared.playGADInterstitial(controller: vc) || AdManager.shared.playGDTAdInterstitia(controller: vc) || AdManager.shared.playFBInterstitialAd(vc: vc)
        }else if times % 2 == 0{
            return AdManager.shared.playGDTAdInterstitia(controller: vc) || AdManager.shared.playFBInterstitialAd(vc: vc) || AdManager.shared.playGADInterstitial(controller: vc)
        }else{
            return AdManager.shared.playFBInterstitialAd(vc: vc) || AdManager.shared.playGADInterstitial(controller: vc) || AdManager.shared.playGDTAdInterstitia(controller: vc)
        }
    }
}
