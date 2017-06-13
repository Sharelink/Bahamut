//
//  AdManager+FB.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/23.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

//Install framework with podfile: pod 'FBAudienceNetwork'

import Foundation
import FBAudienceNetwork

class FBAdConfig {
    var appId:String! = "261188761023242_261188884356563"
    var banner:String! = "261188761023242_261188884356563"
    var inter:String! = "261188761023242_261188997689885"
    var native:String! = "261188761023242_261275851014533"
    
    static var testDevices = [String]()
}

fileprivate var configInstance:FBAdConfig!

//MAKR: FB Banner
extension AdConfig{
    static var facebookConfig:FBAdConfig{
        if configInstance == nil {
            configInstance = FBAdConfig()
            if let dict = AdConfig.adConfigDict["Facebook"] as? NSDictionary{
                configInstance.appId = dict["appId"] as? String
                configInstance.inter = dict["inter"] as? String
                configInstance.native = dict["native"] as? String
                configInstance.banner = dict["banner"] as? String
                if let testDevices = dict["testDevices"] as? [String]{
                    FBAdConfig.testDevices.append(contentsOf: testDevices)
                }
            }
        }
        return configInstance
    }
}

extension AdBannerContainer:FBAdViewDelegate{
    func addFBBanner() {
        let adSize = BANNER_AD_SUGGEST_SIZE_320x50
        var pos = CGPoint()
        pos.y = self.frame.height - adSize.height
        pos.x = (self.frame.width - adSize.width) / 2
        let adview = FBAdView(placementID: AdConfig.facebookConfig.banner, adSize: FBAdSize(size: adSize), rootViewController: self.rootController)
        adview.frame.origin = pos
        adview.delegate = self
        self.addBanner(banner: adview)
        adview.loadAd()
    }
    
    func adViewDidLoad(_ adView: FBAdView) {
        self.setBannerReady(banner: adView)
    }
    
    func adViewDidClick(_ adView: FBAdView) {
        self.hideAd30Mins()
    }
}


//MARK: FBInterstitialAd
private var fbInterstitialAd:FBInterstitialAd!

extension AdManager:FBInterstitialAdDelegate{
    func configureFBAd() {
        #if DEBUG
            FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
        #else
            FBAdSettings.clearTestDevices()
            FBAdSettings.addTestDevices(FBAdConfig.testDevices)
        #endif
    }
    
    func createFBInterstitialAd() {
        let placeId = AdConfig.facebookConfig.inter!
        fbInterstitialAd = FBInterstitialAd(placementID: placeId)
        fbInterstitialAd.delegate = self
        fbInterstitialAd.load()
    }
    
    func playFBInterstitialAd(vc:UIViewController) -> Bool {
        if fbInterstitialAd.isAdValid {
            fbInterstitialAd.show(fromRootViewController: vc)
            return true
        }
        return false
    }
    
    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {}
    
    func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        debugPrint(error)
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(AdManager.interstitialFbAdTimerTick(a:)), userInfo: nil, repeats: false)
    }
    
    func interstitialFbAdTimerTick(a:Timer) {
        self.createFBInterstitialAd()
    }
}

//MARK: FB Native

private var nativeAds = [FBNativeAd:NativeAdResult]()

extension AdManager:FBNativeAdDelegate{
    static var domainFacebook:String{ return "facebook" }
    
    func LoadFBNativeAd() -> NativeAdResult {
        let result = NativeAdResult()
        result.domain = AdManager.domainFacebook
        let fbNativeAd = FBNativeAd(placementID: AdConfig.facebookConfig.native)
        fbNativeAd.delegate = self
        result.origin = fbNativeAd
        nativeAds[fbNativeAd] = result
        DispatchQueue.global().async {
            fbNativeAd.load()
        }
        return result
    }
    
    func nativeAdDidLoad(_ nativeAd: FBNativeAd) {
        if let result = nativeAds.removeValue(forKey: nativeAd){
            result.onNativeAdLoaded?(result)
        }
    }
    
    func nativeAd(_ nativeAd: FBNativeAd, didFailWithError error: Error) {
        if let result = nativeAds.removeValue(forKey: nativeAd){
            result.error = error
            result.onNativeAdLoadFail?(result)
        }
    }
}
