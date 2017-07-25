//
//  UserSetting.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/5.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

//MARK: UserSetting
class UserSetting
{
    
    static func getSettingKey(_ setting:String) -> String{
        return "\(UserSetting.lastLoginAccountId ?? "no_login"):\(setting)"
    }
    
    static func isSettingEnable(_ setting:String) -> Bool{
        return UserDefaults.standard.bool(forKey: getSettingKey(setting))
    }
    
    static func setSetting(_ setting:String,enable:Bool)
    {
        UserDefaults.standard.set(enable, forKey: getSettingKey(setting))
    }
    
    static func enableSetting(_ setting:String)
    {
        setSetting(setting, enable: true)
    }
    
    static func disableSetting(_ setting:String)
    {
        setSetting(setting, enable: false)
    }
    
    static func setUserIntValue(_ setting:String,value:Int){
        let key = getSettingKey(setting)
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func getUserIntValue(_ setting:String) -> Int{
        let key = getSettingKey(setting)
        return UserDefaults.standard.integer(forKey: key)
    }
    
    static func getUserNumberValue(_ setting:String) -> NSNumber?{
        return getUserValue(setting) as? NSNumber
    }
    
    static func setUserNumberValue(_ setting:String,value:NSNumber){
        setUserValue(setting, value: value)
    }
    
    static func setUserValue(_ setting:String,value:Any){
        let key = getSettingKey(setting)
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func getUserValue(_ setting:String) -> Any?{
        let key = getSettingKey(setting)
        return UserDefaults.standard.object(forKey: key)
    }
}

//MARK Account
extension UserSetting{
    static func setDefaultUser(){
        UserSetting.lastLoginAccountId = "0000"
        UserSetting.userId = "0000"
    }
    
    static var lastLoginAccountId:String!{
        get{
            return UserDefaults.standard.value(forKey: "lastLoginAccountId") as? String
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "lastLoginAccountId")
        }
    }
    
    static var isUserLogined:Bool{
        get{
            return UserDefaults.standard.bool(forKey: "isUserLogined")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "isUserLogined")
        }
    }
    
    fileprivate static var _userId:String!
    static var userId:String!{
        get{
            if _userId == nil{
                _userId = UserDefaults.standard.value(forKey: "userId") as? String
            }
            return _userId
        }
        set{
            _userId = newValue
            UserDefaults.standard.setValue(newValue, forKey: "userId")
        }
    }
    
    static var token:String!{
        get{
            return UserDefaults.standard.value(forKey: "token") as? String
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "token")
        }
    }
}

//MARK: Base Record
extension UserSetting{
    static var launchTimes:Int{
        get{
            return UserSetting.getUserIntValue("launch_times")
        }
        set{
            UserSetting.setUserIntValue("launch_times", value: newValue)
        }
    }
    
    static func incLaunchTimes(){
        UserSetting.launchTimes += 1
    }
    
    static func setDefaultUserAndIncLaunchTimes(){
        UserSetting.setDefaultUser()
        incLaunchTimes()
    }
}

//MARK: Debug or Review
extension UserSetting{
    static var godMode = false
    
    static var reviewing:Int{
        get{
            return UserSetting.getUserIntValue("app_reviewing_vcode")
        }
        set{
            UserSetting.setUserIntValue("app_reviewing_vcode", value: newValue)
        }
    }
    
    static var isAppstoreReviewing:Bool{
        get{
            return UserDefaults.standard.bool(forKey: "isAppstoreReviewId")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "isAppstoreReviewId")
        }
    }
}
