//
//  BahamutSetting.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class BahamutConfig
{
    static let SharelinkVersion = "1.2"
    static let sharelinkName = NSLocalizedString("SHARELINK_NAME", comment: "")
    static let sharelinkPrivacyPage = "http://sharelink.online/privacy.html"
    static let sharelinkEmail = "bahamut-sharelink@outlook.com"
    static let sharelinkOuterExecutorUrlPrefix = "http://sharelink.online/ExeSharelink?cmd="
    
    static let sharelinkAppStoreId = "1059287119"
    
    static let umengAppkey = "5643e78367e58ec557005b9f"
    static let shareSDKAppkey = "b96b8b48572e"
    
    static let facebookAppkey = "897418857006645"
    static let facebookAppScrect = "3c5fbcbc22201f96e1b5e93f7a0a69ff"
    
    static let wechatAppkey = "wx661037d16f05eb0b"
    static let wechatAppScrect = "d4624c36b6795d1d99dcf0547af5443d"
    
    static let qqAppkey = "1104930500"
    
    static let weiboAppkey = "179608154"
    static let weiboAppScrect = "b79d50fb87ded0d281492b3113f3f988"
}

class BahamutSetting
{
    static var lang:String = "en"
    static var contry:String = "US"
    static var deviceToken:String = ""
    
    static var loginApi:String{
        get{
            if let api = NSUserDefaults.standardUserDefaults().valueForKey("loginApi") as? String{
                return api
            }
            return "http://auth.sharelink.online:8086/Account/AjaxLogin"
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey:"loginApi")
        }
    }
    
    static var registAccountApi:String{
        get{
            if let api = NSUserDefaults.standardUserDefaults().valueForKey("registAccountApi") as? String
            {
                return api
            }
            return "http://auth.sharelink.online:8086/Account/AjaxRegist"
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey:"registAccountApi")
        }
    }
    
    static var shareLinkApiServer:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("shareLinkApiServer") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "shareLinkApiServer")
        }
    }
    
    static var fileApiServer:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("fileApiServer") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "fileApiServer")
        }
    }
    
    static var chicagoServerHost:String!{
        get{
            return NSUserDefaults.standardUserDefaults().valueForKey("chicagoServerHost") as? String
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "chicagoServerHost")
        }
    }
    
    static var chicagoServerHostPort:UInt16{
        get{
            let port = NSUserDefaults.standardUserDefaults().integerForKey("chicagoServerHostPort")
            return UInt16(port)
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(Int(newValue), forKey: "chicagoServerHostPort")
        }
    }
    
    
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
            if _userId == nil
            {
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
}