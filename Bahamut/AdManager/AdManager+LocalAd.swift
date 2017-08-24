
//
//  LocalAd.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/24.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

protocol LocalAdBannerViewDelegate : class{
    func localAdBannerLoaded(ad:LocalAdBannerView)
    func localAdBannerClicked(ad:LocalAdBannerView)
}

extension Notification.Name{
    static let LocalAdBannerViewOnClick = Notification.Name("LocalAdBannerViewOnClick")
}

private let LocalAdClickedUrlArrayKey = "LocalAdClickedUrlArray"

class LocalAdBannerView: UIView {
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initBanner()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initBanner()
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
        debugLog("Deinited:\(self.description)")
    }
    
    private var imageView:UIImageView!
    
    private var timer:Timer!
    
    var interval:TimeInterval = 0{
        didSet{
            if interval != oldValue {
                timer?.invalidate()
                if interval != 0 {
                    self.ticking = 0
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(LocalAdBannerView.reloadCurrentAdTimer(a:)), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    private var ticking:TimeInterval = 0
    
    
    func reloadCurrentAdTimer(a:Timer) {
        if self.alpha <= 0 || self.isHidden{
            return
        }
        
        ticking += 1
        if ticking >= interval{
            LocalAdBannerView.adIndex = (LocalAdBannerView.adIndex + 1) % self.adInfos.count
            self.reloadCurrentAd()
            ticking = 0
        }
    }
    
    func initBanner() {
        imageView = UIImageView()
        self.addSubview(imageView)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocalAdBannerView.onClickBanner(a:))))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.frame = self.bounds
    }
    
    func onClickBanner(a:Any) {
        if let url = currentInfo?.0{
            if UIApplication.shared.openURL(url){
                NotificationCenter.default.post(name: .LocalAdBannerViewOnClick, object: self, userInfo: ["URL":url.absoluteString])
                var clickedarr = UserDefaults.standard.stringArray(forKey: LocalAdClickedUrlArrayKey) ?? []
                if !clickedarr.contains(url.absoluteString){
                    clickedarr.append(url.absoluteString)
                    UserDefaults.standard.set(clickedarr, forKey: LocalAdClickedUrlArrayKey)
                    UserDefaults.standard.synchronize()
                }
                self.delegate?.localAdBannerClicked(ad: self)
            }
        }
    }
    
    private var adInfos = [(URL,UIImage)]()
    static private var adIndex = 0
    private var currentInfo:(URL,UIImage)?{
        if adInfos.count > 0{
            if LocalAdBannerView.adIndex < 0{
                LocalAdBannerView.adIndex = abs(LocalAdBannerView.adIndex) % adInfos.count
            }
            return adInfos[LocalAdBannerView.adIndex % adInfos.count]
        }else{
            return nil
        }
    }
    
    weak var delegate:LocalAdBannerViewDelegate?
    
    func addAdInfo(url:URL,img:UIImage) {
        adInfos.append((url, img))
    }
    
    func reloadCurrentAd() {
        if let img = currentInfo?.1{
            self.imageView?.image = img
            self.delegate?.localAdBannerLoaded(ad: self)
        }
    }
    
    func loadAndShow() {
        reloadCurrentAd()
    }
}

extension AdBannerContainer:LocalAdBannerViewDelegate{
    
    @discardableResult
    func addLocalBanner(interval:TimeInterval,ignoreClickedUrls:Bool = true) -> Bool {
        if let dict = AdConfig.adConfigDict["LocalAd"] as? NSDictionary{
            let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode)
            if let code = (countryCode! as AnyObject).description,let adInfos = (dict[code] ?? dict["default"]) as? Array<NSDictionary>{
                if adInfos.count > 0 {
                    let adSize = BANNER_AD_SUGGEST_SIZE_320x50
                    var pos = CGPoint()
                    pos.y = self.frame.height - adSize.height
                    pos.x = (self.frame.width - adSize.width) / 2
                    let banner = LocalAdBannerView(frame:CGRect(origin: pos, size: adSize))
                    
                    let clickeds = UserDefaults.standard.stringArray(forKey: LocalAdClickedUrlArrayKey) ?? []
                    var clickedInfos = [(URL,UIImage)]()
                    
                    for adInfo in adInfos {
                        if let imgName = adInfo["img"] as? String,let urlStr = adInfo["url"] as? String,let url = URL(string: urlStr),let img = UIImage(named: imgName){
                            if ignoreClickedUrls && clickeds.contains(url.absoluteString){
                                clickedInfos.append((url, img))
                            }else{
                                banner.addAdInfo(url:url , img: img)
                            }
                        }
                    }
                    
                    if clickedInfos.count == adInfos.count{
                        for (url,img) in clickedInfos {
                            banner.addAdInfo(url:url , img: img)
                        }
                    }
                    
                    banner.delegate = self
                    banner.interval = interval
                    self.addBanner(banner: banner)
                    banner.loadAndShow()
                    return true
                }
            }
        }
        return false
    }
    
    func localAdBannerLoaded(ad: LocalAdBannerView) {
        setBannerReady(banner: ad)
    }
    
    func localAdBannerClicked(ad: LocalAdBannerView) {
        hideAd30Mins()
    }
}
