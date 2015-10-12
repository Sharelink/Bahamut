//
//  BahamutConfig.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

class BahamutConfig
{
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
}