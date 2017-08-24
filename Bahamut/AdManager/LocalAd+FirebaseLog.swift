//
//  LocalAd+FirebaseLog.swift
//  runningball
//
//  Created by Alex Chow on 2017/8/17.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import FirebaseAnalytics

extension AdManager{
    func addLocalAdFirebaseLog() {
        NotificationCenter.default.addObserver(self, selector: #selector(AdManager.onLocalAdClickFirebaseLog(a:)), name: .LocalAdBannerViewOnClick, object: nil)
    }
    
    func onLocalAdClickFirebaseLog(a:Notification) {
        Analytics.logEvent("LocalAdClick", parameters: a.userInfo as? [String:Any])
    }
}
