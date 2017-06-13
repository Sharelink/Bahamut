//
//  AdManager.swift
//  BrakeSpinner
//
//  Created by Alex Chow on 2017/5/22.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

enum AdType {
    case banner,inter,native,splash,reward
}

let BANNER_AD_SUGGEST_SIZE_320x50 = CGSize(width: 320, height: 50) //For iPhone
let BANNER_AD_SUGGEST_SIZE_468x60 = CGSize(width:468, height:60) //For iPad
let BANNER_AD_SUGGEST_SIZE_728x90 = CGSize(width:728, height:90) //For iPad

let AdEventLoaded = "AdEventLoaded"
let AdEventLoadFail = "AdEventLoadFail"

extension String{
    func adMgrLocalized()->String{
        return LocalizedString(self, tableName: "AdManager", bundle: Bundle.main)
    }
}

class AdNotificationInfo {
    var domain:String!
    var adType:AdType!
    var adEvent:String!
    var adObject:Any!
    var extra:[AnyHashable:Any]?
    static func fromNotificationUserInfo(userInfo:[AnyHashable:Any]?) -> AdNotificationInfo? {
        return userInfo?["infovalue"] as? AdNotificationInfo
    }
}

class AdManager:NotificationCenter {
    static let adManagerNotification = Notification.Name("adManagerNotification")
    
    static let shared:AdManager = {
        return AdManager()
    }()
    
    func loadConfig() {
        AdConfig.load(url: Bundle.main.url(forResource: "AdConfig", withExtension: "plist")!)
    }
    
    func postAdNotification(info:AdNotificationInfo) {
        self.post(name: AdManager.adManagerNotification, object: self, userInfo: ["infovalue":info])
    }
}

typealias AdManagerNativeAdCallback = (NativeAdResult)->Void

class NativeAdResult {
    var origin:Any?
    var error:Any?
    var domain:String!
    var onNativeAdLoaded:AdManagerNativeAdCallback?
    var onNativeAdLoadFail:AdManagerNativeAdCallback?
}
