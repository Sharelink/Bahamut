
//
//  LocalAd.swift
//  smashanything
//
//  Created by Alex Chow on 2017/5/24.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

protocol LocalAdBannerViewDelegate {
    func localAdBannerLoaded(ad:LocalAdBannerView)
    func localAdBannerClicked(ad:LocalAdBannerView)
}

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
    
    private var imageView:UIImageView!
    
    private var timer:Timer!
    
    var interval:TimeInterval = 0{
        didSet{
            if interval != oldValue {
                timer?.invalidate()
                if interval != 0 {
                    self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(LocalAdBannerView.reloadCurrentAdTimer(a:)), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    func reloadCurrentAdTimer(a:Timer) {
        self.adIndex = (self.adIndex + 1) % self.adInfos.count
        self.reloadCurrentAd()
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
                self.delegate?.localAdBannerClicked(ad: self)
            }
        }
    }
    
    private var adInfos = [(URL,UIImage)]()
    private var adIndex = 0
    private var currentInfo:(URL,UIImage)?{
        if adIndex >= 0 && adIndex <= adInfos.count - 1{
            return adInfos[adIndex]
        }else{
            return nil
        }
    }
    
    var delegate:LocalAdBannerViewDelegate?
    
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
    func addLocalBanner(interval:TimeInterval) -> Bool {
        if let dict = AdConfig.adConfigDict["LocalAd"] as? NSDictionary{
            let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode)
            if let code = (countryCode! as AnyObject).description,let adInfos = (dict[code] ?? dict["default"]) as? Array<NSDictionary>{
                if adInfos.count > 0 {
                    let adSize = BANNER_AD_SUGGEST_SIZE_320x50
                    var pos = CGPoint()
                    pos.y = self.frame.height - adSize.height
                    pos.x = (self.frame.width - adSize.width) / 2
                    let banner = LocalAdBannerView(frame:CGRect(origin: pos, size: adSize))
                    
                    for adInfo in adInfos {
                        if let imgName = adInfo["img"] as? String,let urlStr = adInfo["url"] as? String,let url = URL(string: urlStr),let img = UIImage(named: imgName){
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
