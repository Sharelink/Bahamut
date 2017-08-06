//
//  LockScreenNotification.swift
//  notouchphonealarm
//
//  Created by Alex Chow on 2017/7/26.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
extension NSNotification.Name{
    static let ScreenDidLocked:Notification.Name = Notification.Name("LockScreenNotification.ScreenDidLocked")
    static let ScreenDidUnLocked:Notification.Name = Notification.Name("LockScreenNotification.ScreenDidUnLocked")
}

class LockScreenHelper:NSObject {
    private static let notificationLock = "com.apple.springboard.lockcomplete" as CFString
    private static let notificationChange = "com.apple.springboard.lockstate" as CFString
    private static let notificationPwdUI = "com.apple.springboard.hasBlankedScreen" as CFString
    
    private(set) static var screenLocked:Bool = false
    
    static func startLockScreenObservers(){
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { (center, _, name, _, userInfo) in
        }, notificationLock, nil, .deliverImmediately)
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { (center, _, name, _, userInfo) in
        }, notificationChange, nil, .deliverImmediately)
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { (center, _, name, _, userInfo) in
            if LockScreenHelper.screenLocked{
                LockScreenHelper.screenLocked = false
                NotificationCenter.default.post(name: .ScreenDidUnLocked, object: nil)
            }else{
                LockScreenHelper.screenLocked = true
                NotificationCenter.default.post(name: .ScreenDidLocked, object: nil)
            }
        }, notificationPwdUI, nil, .deliverImmediately)
    }
    
    static func stopLockScreenObservers(){
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, CFNotificationName(rawValue: notificationLock), nil)
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, CFNotificationName(rawValue: notificationChange), nil)
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, CFNotificationName(rawValue: notificationPwdUI), nil)
    }
}
