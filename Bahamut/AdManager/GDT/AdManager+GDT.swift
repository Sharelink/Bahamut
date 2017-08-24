//
//  AdManager+GDT.swift
//  BrakeSpinner
//
//  Created by Alex Chow on 2017/5/22.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

//Copy libGDTMobSDK.a to project directory and add reference to Target
//Import h file in Bridge Header: #import "GDTAd.h"

import Foundation

class GDTConfig {
    var appId:String!
    var banner:String!
    var inter:String!
    var splash:String!
    var native:String!
}

fileprivate var configInstance:GDTConfig!

extension AdConfig{
    static var gdtConfig:GDTConfig{
        if configInstance == nil {
            configInstance = GDTConfig()
            if let dict = AdConfig.adConfigDict["GDT"] as? NSDictionary{
                configInstance.appId = dict["appId"] as? String
                configInstance.banner = dict["banner"] as? String
                configInstance.inter = dict["inter"] as? String
                configInstance.native = dict["native"] as? String
                configInstance.splash = dict["splash"] as? String
            }
        }
        return configInstance
    }
}

extension AdBannerContainer:GDTMobBannerViewDelegate{
    func addGDTBanner(interval:Int32) {
        let adSize = BANNER_AD_SUGGEST_SIZE_320x50
        var pos = CGPoint()
        pos.y = self.frame.height - adSize.height
        pos.x = (self.frame.width - adSize.width) / 2
        
        let frame = CGRect(origin: pos, size: adSize)
        if let banner = GDTMobBannerView(frame: frame, appkey: AdConfig.gdtConfig.appId, placementId: AdConfig.gdtConfig.banner){
            banner.currentViewController = rootController
            banner.isAnimationOn = false
            banner.showCloseBtn = false
            banner.isGpsOn = true
            banner.interval = interval
            banner.delegate = self
            self.addBanner(banner: banner)
            banner.loadAdAndShow()
        }
    }
    
    func bannerViewDidPresentFullScreenModal() {
        self.hideAd30Mins()
    }
    
    private var gdtBanners:[GDTMobBannerView]{
        return self.banners.filter{$0.banner is GDTMobBannerView}.map{$0.banner as! GDTMobBannerView}
    }
    
    func bannerViewDidReceived() {
        
        for banner in gdtBanners {
            self.setBannerReady(banner: banner)
            
            if curBannerView != nil &&  curBannerView != banner{
                DispatchQueue.main.afterMS(10, handler: { 
                    debugPrint("Hide GDT Banner")
                    banner.superview?.sendSubview(toBack: banner)
                    banner.alpha = 0
                })
            }
        }
    }
    
    func bannerViewWillClose() {
        
    }
    
    func bannerViewClicked() {
        
    }
    
    func bannerViewFail(toReceived error: Error!) {
        debugPrint(error)
    }
}

private var gdtInterstitial:GDTMobInterstitial!

private var splashBottomView:UIView!
private var splash:GDTSplashAd!
extension AdManager:GDTMobInterstitialDelegate{
    static var domainGDT:String{ return "GDT" }
    
    func createGDTInterstitial()  {
        gdtInterstitial = GDTMobInterstitial(appkey: AdConfig.gdtConfig.appId, placementId: AdConfig.gdtConfig.inter)
        gdtInterstitial.delegate = self
        gdtInterstitial?.loadAd()
    }
    
    func playGDTAdInterstitia(controller:UIViewController) -> Bool {
        if let gdti = gdtInterstitial,gdti.isReady {
            gdti.present(fromRootViewController: controller)
            return true
        }
        return false
    }
    
    func interstitialClicked(_ interstitial: GDTMobInterstitial!) {
        
    }
    
    func interstitialDidDismissScreen(_ interstitial: GDTMobInterstitial!) {
        interstitial.loadAd()
    }
    
    func interstitialSuccess(toLoadAd interstitial: GDTMobInterstitial!) {
        
    }
    
    func interstitialFail(toLoadAd interstitial: GDTMobInterstitial!, error: Error!) {
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(AdManager.interstitialGDTAdTimerTick(a:)), userInfo: nil, repeats: false)
    }
    
    func interstitialGDTAdTimerTick(a:Timer) {
        self.createGDTInterstitial()
    }
}

private var splashAdLoaded = false
private var rootViewController:UIViewController!
private var keyWindow:UIWindow!

extension AdManager:GDTSplashAdDelegate{
    
    func setLaunchScreenBackground(window:UIWindow,launchScr:UIViewController,dismissAfterMS:UInt64) {
        window.makeKeyAndVisible()
        if let rootVC = window.rootViewController{
            splashAdLoaded = false
            rootViewController = rootVC
            keyWindow = window
            window.rootViewController = launchScr
            window.makeKeyAndVisible()
            DispatchQueue.main.afterMS(dismissAfterMS, handler: {
                if splashAdLoaded == false{
                    window.rootViewController = rootVC
                    window.makeKeyAndVisible()
                    rootViewController = nil
                    keyWindow = nil
                }
            })
        }
    }
    
    func setLaunchScreenBackground(window:UIWindow,dismissAfterMS:UInt64,launchScrBoardId:String = "LaunchScreen",viewId:String = "LaunchScreen"){
        let launchScrVC = UIViewController.instanceFromStoryBoard(launchScrBoardId, identifier: viewId)
        setLaunchScreenBackground(window: window, launchScr: launchScrVC, dismissAfterMS: dismissAfterMS)
    }
    
    func configureGDTAndShowSplashAd(window:UIWindow,bottomView:UIView?,delay:TimeInterval) {
        let splashAd = GDTSplashAd(appkey: AdConfig.gdtConfig.appId, placementId: AdConfig.gdtConfig.splash)
        splashAd?.fetchDelay = Int32(delay)
        splashAd?.delegate = self
        if bottomView == nil{
            splashAd?.loadAndShow(in: window)
        }else{
            splashBottomView = bottomView
            splashAd?.loadAndShow(in: window, withBottomView: splashBottomView)
        }
        splash = splashAd
    }
    
    func configureGDTAndShowSplashAd(window:UIWindow,bottomLogo:UIImage,delay:TimeInterval) {
        let logo = UIImageView(image:bottomLogo)
        logo.contentMode = .center
        let bottomView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 100))
        bottomView.addSubview(logo)
        logo.center = bottomView.center
        bottomView.backgroundColor = UIColor.white
        configureGDTAndShowSplashAd(window:window,bottomView:bottomView,delay:delay)
    }
    
    func splashAdSuccessPresentScreen(_ splashAd: GDTSplashAd!) {
        splashAdLoaded = true
    }
    
    func splashAdClicked(_ splashAd: GDTSplashAd!) {
        trySetRootVC()
    }
    
    func splashAdFail(toPresent splashAd: GDTSplashAd!, withError error: Error!) {
        trySetRootVC()
    }
    
    func splashAdWillClosed(_ splashAd: GDTSplashAd!) {
        trySetRootVC()
    }
    
    private func trySetRootVC() {
        if let rvc = rootViewController{
            DispatchQueue.main.async {
                keyWindow?.rootViewController = rvc
                keyWindow?.makeKeyAndVisible()
                rootViewController = nil
                keyWindow = nil
            }
        }
    }
}
