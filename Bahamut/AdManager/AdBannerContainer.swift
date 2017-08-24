//
//  AdBannerContainer.swift
//  BrakeSpinner
//
//  Created by Alex Chow on 2017/5/23.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

class BannerViewInfo{
    init(banner:UIView,isReady:Bool) {
        self.banner = banner
        self.isReady = isReady
    }
    var banner:UIView
    var isReady = false
}

protocol AdBannerContainerClickCloseButtonDelegate : class{
    func onAdBannerCloseButtonClicked(sender:AdBannerContainer)
}

class AdBannerContainer: UIView {
    
    
    
    static let onBannerSetHidden = Notification.Name("AdBannerContainer.onBannerSetHidden")
    static let onBannerSetVisible = Notification.Name("AdBannerContainer.onBannerSetVisible")
    weak var rootController:UIViewController!
    
    weak var closeHandler:AdBannerContainerClickCloseButtonDelegate?
    
    private var hideUntil:Date!
    
    private var autoSwitchBannerInterval:TimeInterval = 0
    
    private var closeImage:UIImageView!
    
    var clickCloseAdEnabled = true{
        didSet{
            closeImage?.isHidden = !clickCloseAdEnabled
        }
    }
    
    
    private var curIndex = 0
    private(set) var banners = [BannerViewInfo]()
    private var cachedBannersFrame = [CGRect]()
    
    var curBannerView:UIView?{
        if curIndex < banners.count - 1 {
            return banners[curIndex].banner
        }
        return nil
    }
    
    private var timer:Timer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initCloseImage()
    }
    
    func onCloseClick(a:UITapGestureRecognizer) {
        if closeHandler == nil{
            self.rootController?.showAlert("CLOSE_BANNER_AD".adMgrLocalized(), msg: "CLOSE_BANNER_AD_TIPS".adMgrLocalized())
        }else{
            closeHandler?.onAdBannerCloseButtonClicked(sender: self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCloseImage()
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
        self.removeAllSubviews()
        debugLog("Deinited:\(self.description)")
    }
    
    private func initCloseImage(){
        self.clipsToBounds = true
        closeImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        closeImage?.image = UIImage(named: "adbanner_close")
        closeImage?.isUserInteractionEnabled = true
        closeImage?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AdBannerContainer.onCloseClick(a:))))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let hu = hideUntil,hu.totalSecondsSince1970.doubleValue > Date().totalSecondsSince1970.doubleValue {
            self.alpha = 0
            self.isHidden = true
        }else if self.alpha == 0{
            self.alpha = 1
            self.isHidden = false
            NotificationCenter.default.post(name: AdBannerContainer.onBannerSetVisible, object: self)
        }
        if let b = curBannerView{
            self.bringSubview(toFront: b)
        }
        if let close = closeImage{
            self.bringSubview(toFront: close)
        }
    }
    
    @discardableResult
    func hideAd30Mins() -> Bool {
        return hideAd(forTimeInterval: 30 * 60)
    }
    
    @discardableResult
    func hideAd(forTimeInterval:TimeInterval) -> Bool {
        if clickCloseAdEnabled {
            var delay = Date()
            delay.addTimeInterval(forTimeInterval)
            hideUntil = delay
            setNeedsLayout()
            layoutIfNeeded()
            NotificationCenter.default.post(name: AdBannerContainer.onBannerSetHidden, object: self)
        }
        return clickCloseAdEnabled
    }
    
    func schaduleAdSwitchTimer(switchBannerInterval:TimeInterval){
        self.autoSwitchBannerInterval = max(switchBannerInterval, 2)
        self.timer?.invalidate()
        if autoSwitchBannerInterval <= 0 {
            self.timer = nil
        }else{
            let sel = #selector(AdBannerContainer.onSwitchBannerTimerTick(t:))
            self.timer = Timer.scheduledTimer(timeInterval: autoSwitchBannerInterval, target: self, selector: sel, userInfo: nil, repeats: true)
        }
    }
    
    func onSwitchBannerTimerTick(t:Timer) {
        switchBanner()
    }
    
    func addBanner(banner:UIView,isReady:Bool = false) {
        self.addSubview(banner)
        let info = BannerViewInfo(banner: banner, isReady: isReady)
        self.banners.append(info)
        banner.alpha = 0
    }
    
    private func nextReadyBannerIndex(cur:Int) -> Int? {
        for i in 0..<banners.count {
            let index = (cur + i + 1) % banners.count
            if banners[index].isReady {
                return index
            }
        }
        return nil
    }
    
    @discardableResult
    func setBannerReady(banner:UIView) -> Bool {
        
        for bannerInfo in banners {
            if bannerInfo.banner == banner{
                let switchOnece = nextReadyBannerIndex(cur: curIndex) == nil
                bannerInfo.isReady = true
                if switchOnece {
                    switchBanner()
                }
                return true
            }
        }
        return false
    }
    
    func switchBanner() {
        let now = Date().timeIntervalSince1970
        let hu = hideUntil?.timeIntervalSince1970 ?? 0
        if hu > now {
            return
        }
        if self.banners.count > 1 {
            if let nextIndex = nextReadyBannerIndex(cur: curIndex) {
                self.banners[curIndex % self.banners.count ].banner.alpha = 0
                if nextIndex == curIndex {
                    self.banners[nextIndex].banner.alpha = 1
                }else{
                    curIndex = nextIndex
                    for bn in self.banners {
                        bn.banner.alpha = 0
                    }
                    let front = self.banners[curIndex].banner
                    self.bringSubview(toFront: front)
                    UIView.beginAnimations(nil, context: nil)
                    UIView.setAnimationDuration(1)
                    front.alpha = 1
                    UIView.commitAnimations()
                }
            }
        }else if self.banners.count == 1{
            self.banners.first?.banner.alpha = 1
        }
        
        if let banner = curBannerView{
            if banner.superview == nil {
                self.addSubview(banner)
            }
            
            if closeImage.superview == nil {
                self.addSubview(closeImage)
            }
            closeImage.frame.origin = CGPoint(x: banner.frame.origin.x + banner.frame.width - closeImage.frame.width, y: 0)
            self.bringSubview(toFront: closeImage)
        }
    }
}
