//
//  AppRateHelper.swift
//  snakevsblock
//
//  Created by Alex Chow on 2017/7/8.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

let AppRateNotification = Notification.Name("AppRateNotification")
let kAppRateNotificationEvent = "kAppRateNotificationEvent"

class AppRateHelper:NSObject {
    
    static let shared:AppRateHelper = {
        return AppRateHelper()
    }()
    
    private static var appId:String!
    private static var nextRateAlertDays:Int = 1
    
    private var lastShowDate:NSNumber{
        get{
            let date = UserDefaults.standard.double(forKey: "AppRateLastDate")
            return NSNumber(value: date)
        }
        set{
            UserDefaults.standard.set(newValue.doubleValue, forKey: "AppRateLastDate")
        }
    }
    
    private(set) var isUserRated:Bool{
        get{
            return UserDefaults.standard.bool(forKey: "AppRateHelper_USER_RATED_US")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "AppRateHelper_USER_RATED_US")
        }
    }
    
    func configure(appId:String,nextRateAlertDays:Int){
        if lastShowDate.doubleValue < 100 {
            lastShowDate = NSNumber(value: Date().timeIntervalSince1970)
        }
        AppRateHelper.nextRateAlertDays = nextRateAlertDays
        AppRateHelper.appId = appId
    }
    
    private(set) var rateusShown = false
    
    class RateAlertModel {
        var title:String!
        var message:String!
        var actionGoRateTitle:String!
        var actionRejectTitle:String!
        var actionCancelTitle:String!
        
        
        var showConfrimRejectRateUs = false
        
        var confirmRejectTitle:String!
        var confirmRejectMessage:String!
        var actionConfirmRejectGoRate:String!
        var actionConfirmRejectNoRate:String!
    }
    
    func shouldShowRateAlert() -> Bool {
        return !rateusShown && !isUserRated && lastShowDate.int64Value + 24 * 3600 * Int64(AppRateHelper.nextRateAlertDays) < Int64(Date().timeIntervalSince1970)
    }
    
    func clearRatedRecord() {
        isUserRated = false
    }
    
    @discardableResult
    func tryShowRateUsAlert(vc:UIViewController,alertModel:RateAlertModel) -> Bool {
        if shouldShowRateAlert() {
            let like = UIAlertAction(title: alertModel.actionGoRateTitle, style: .default, handler: { (ac) in
                self.postEvent(event: "like_it")
                self.rateus()
            })
            
            let hate = UIAlertAction(title: alertModel.actionRejectTitle, style: .default, handler: { (ac) in
                self.postEvent(event: "hate_it")
                if alertModel.showConfrimRejectRateUs{
                    let ok = UIAlertAction(title: alertModel.actionConfirmRejectGoRate, style: .default, handler: { (a) in
                        self.rateus()
                    })
                    let no = UIAlertAction(title: alertModel.actionConfirmRejectNoRate, style: .cancel, handler: { (a) in
                        
                    })
                    vc.showAlert(alertModel.confirmRejectTitle, msg: alertModel.confirmRejectMessage, actions: [ok,no])
                }
            })
            
            let nextTime = UIAlertAction(title: alertModel.actionCancelTitle, style: .cancel, handler: { (ac) in
                self.postEvent(event: "next_time")
            })
            
            
            vc.showAlert(alertModel.title, msg: alertModel.message, actions: [like,hate,nextTime])
            lastShowDate = NSNumber(value: Date().timeIntervalSince1970)
            rateusShown = true
            return true
        }
        
        return false
    }
    
    func rateus() {
        let url = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(AppRateHelper.appId ?? "")"
        let _ = UIApplication.shared.openURL(URL(string: url)!)
        UserDefaults.standard.set(true, forKey: "AppRateHelper_USER_RATED_US")
        postEvent(event: "go_rate")
    }
    
    private func postEvent(event:String) {
        NotificationCenter.default.post(name: AppRateNotification, object: AppRateHelper.shared, userInfo: [kAppRateNotificationEvent:event])
    }
}

private let eventFirebase = "eventFirebase"
extension AppRateHelper{
    func addRateFirebaseEvent() {
        NotificationCenter.default.addObserver(self, selector: #selector(AppRateHelper.onFirebaseEvent(a:)), name: AppRateNotification, object: eventFirebase)
    }
    
    func removeFirebaseEvent() {
        NotificationCenter.default.removeObserver(self, name: AppRateNotification, object: eventFirebase)
    }
    
    func onFirebaseEvent(a:Notification) {
        if let event = a.userInfo?[kAppRateNotificationEvent] as? String{
            AnManager.shared.firebaseEvent(event: event)
        }
    }
}
