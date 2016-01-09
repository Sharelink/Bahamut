//
//  SharelinkSetting.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class SharelinkConfig
{
    static let appName = NSLocalizedString("SHARELINK_NAME", comment: "")
    static let SharelinkMotto = NSLocalizedString("SHARELINK_MOTTO", comment: "")
}

class SharelinkSetting
{
    static var lang:String = "en"
    static var contry:String = "US"
    static var deviceToken:String = ""
    
    static var loginApi:String{
        get{
            if let api = NSUserDefaults.standardUserDefaults().valueForKey("loginApi") as? String{
                return api
            }
            return BahamutConfig.accountLoginApiUrl
        }
        set{
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey:"loginApi")
        }
    }
    
    static var registAccountApi:String{
        get{
            if let api = NSUserDefaults.standardUserDefaults().valueForKey("registAccountApi") as? String{
                return api
            }
            return BahamutConfig.accountRegistApiUrl
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
}