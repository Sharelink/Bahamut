//
//  AdManager+AdMob.swift
//  BrakeSpinner
//
//  Created by Alex Chow on 2017/5/22.
//  Copyright © 2017年 Bahamut. All rights reserved.
//
//Install framework with podfile: pod 'GoogleMobileAds' or pod 'Firebase/AdMob' if using firebase

import Foundation
import GoogleMobileAds

class AdMobConfig {
    var appId:String! = nil
    var banner:String!
    var inter:String!
    var native:String!
    var reward:String!
    
    static var testDevices = [kGADSimulatorID]
}

fileprivate var configInstance:AdMobConfig!

extension AdConfig{
    static var adMobConfig:AdMobConfig{
        if configInstance == nil {
            configInstance = AdMobConfig()
            if let dict = adConfigDict["AdMob"] as? NSDictionary{
                configInstance.appId = dict["appId"] as? String
                configInstance.inter = dict["inter"] as? String
                configInstance.native = dict["native"] as? String
                configInstance.reward = dict["reward"] as? String
                configInstance.banner = dict["banner"] as? String
                if let testDevices = dict["testDevices"] as? [AnyObject]{
                    AdMobConfig.testDevices.append(contentsOf: testDevices)
                }
            }
        }
        return configInstance
    }
}

var interstitial:GADInterstitial!

class GADInterstitialDefaultDelegate: NSObject,GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        AdManager.shared.createGADAndLoadInterstitial()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(GADInterstitialDefaultDelegate.adTimerTick(a:)), userInfo: nil, repeats: false)
    }
    
    func adTimerTick(a:Timer) {
        AdManager.shared.createGADAndLoadInterstitial()
    }
}

private let interstitialDefaultDelegate = GADInterstitialDefaultDelegate()

extension AdManager{
    static var domainAdMob:String{ return "AdMob" }
    
    func configreAdMob() {
        GADMobileAds.configure(withApplicationID: AdConfig.adMobConfig.appId)
    }
    
    func loadGADRewardAd() {
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(), withAdUnitID: AdConfig.adMobConfig.reward)
    }
    
    func createGADAndLoadInterstitial() {
        interstitial = GADInterstitial(adUnitID: AdConfig.adMobConfig.inter)
        let request = GADRequest()
        request.testDevices = AdMobConfig.testDevices
        interstitial.delegate = interstitialDefaultDelegate
        interstitial.load(request)
    }
    
    func playGADInterstitial(controller:UIViewController) -> Bool {
        if let inter = interstitial,inter.isReady {
            inter.present(fromRootViewController: controller)
            return true
        }
        return false
    }
    
    func playGADRewardAd(controller:UIViewController) -> Bool {
        if GADRewardBasedVideoAd.sharedInstance().isReady{
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: controller)
            return true
        }
        return false
    }
}

extension AdBannerContainer:GADBannerViewDelegate{
    func addAdMobBanner() {
        let admobBanner = GADBannerView()
        let bannerReq = GADRequest()
        
        let adSize = CGSize(width: self.frame.width, height: 50)
        var pos = CGPoint()
        pos.y = self.frame.height - adSize.height
        pos.x = (self.frame.width - adSize.width) / 2
        
        admobBanner.frame = CGRect(origin: pos, size: adSize)
            
        bannerReq.testDevices = AdMobConfig.testDevices
        admobBanner.adUnitID = AdConfig.adMobConfig.banner
        admobBanner.rootViewController = self.rootController
        admobBanner.delegate = self
        
        self.addBanner(banner: admobBanner)
        admobBanner.load(bannerReq)
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.setBannerReady(banner: bannerView)
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        self.hideAd30Mins()
    }
}


private var adMobAds = [NSObject:NativeAdResult]()
extension AdManager:GADNativeExpressAdViewDelegate{
    func loadAdMobNativeExpressAd(vc:UIViewController,height:CGFloat,placeId:String) -> NativeAdResult? {
        let result = NativeAdResult()
        result.domain = AdManager.domainAdMob
        if let gad = GADNativeExpressAdView(adSize: GADAdSizeFullWidthPortraitWithHeight(height)){
            gad.adUnitID = placeId
            gad.rootViewController = vc
            gad.delegate = self
            let req = GADRequest()
            req.testDevices = AdMobConfig.testDevices
            result.origin = gad
            adMobAds[gad] = result
            DispatchQueue.global().async {
                gad.load(req)
            }
            return result
        }
        return nil
    }
    
    func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
        if let res = adMobAds.removeValue(forKey: nativeExpressAdView){
            res.onNativeAdLoaded?(res)
        }
    }
    
    func nativeExpressAdView(_ nativeExpressAdView: GADNativeExpressAdView, didFailToReceiveAdWithError error: GADRequestError) {
        if let res = adMobAds.removeValue(forKey: nativeExpressAdView){
            res.error = error
            res.onNativeAdLoaded?(res)
        }
    }
}
