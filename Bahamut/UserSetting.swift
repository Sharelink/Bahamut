//
//  UserSetting.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/5.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
class UserSetting
{
    static var lastLoginAccountId:String!{
        get{
        return NSUserDefaults.standardUserDefaults().valueForKey("lastLoginAccountId") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "lastLoginAccountId")
        }
    }
    
    static var isUserLogined:Bool{
        get{
        return NSUserDefaults.standardUserDefaults().boolForKey("isUserLogined")
        }
        set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "isUserLogined")
        }
    }
    
    private static var _userId:String!
    static var userId:String!{
        get{
        if _userId == nil{
        _userId = NSUserDefaults.standardUserDefaults().valueForKey("userId") as? String
        }
        return _userId
        }
        set{
            _userId = newValue
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "userId")
        }
    }
    
    static var token:String!{
        get{
        return NSUserDefaults.standardUserDefaults().valueForKey("token") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "token")
        }
    }
    
    static func getSettingKey(setting:String) -> String{
        return "\(UserSetting.lastLoginAccountId):\(setting)"
    }
    
    static func isSettingEnable(setting:String) -> Bool{
        return NSUserDefaults.standardUserDefaults().boolForKey(getSettingKey(setting))
    }
    
    static func setSetting(setting:String,enable:Bool)
    {
        NSUserDefaults.standardUserDefaults().setBool(enable, forKey: getSettingKey(setting))
    }
    
    static func enableSetting(setting:String)
    {
        setSetting(setting, enable: true)
    }
    
    static func disableSetting(setting:String)
    {
        setSetting(setting, enable: false)
    }
}