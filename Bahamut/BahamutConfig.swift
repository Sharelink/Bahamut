//
//  SharelinkSetting.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

let AppleStoreReviewAccountIds = ["147275","147276"];
var SharelinkVersion:String{
    if let infoDic = Sharelink.mainBundle().infoDictionary
    {
        let version = infoDic["CFBundleShortVersionString"] as! String
        return version
    }
    return "1.0.24"
}

var SharelinkName:String{
    return "SHARELINK_NAME".localizedString()
}

let SharelinkRFAppKey = "5e6c827f2fcb04e8fca80cf72db5ba004508246b"

class BahamutConfigObject:EVObject
{
    var accountApiUrlPrefix:String!
    var accountRegistApiUrl:String!
    var accountLoginApiUrl:String!
    
    var appPrivacyPage:String!
    var bahamutAppEmail:String!
    var bahamutAppOuterExecutorUrlPrefix:String!
    
    var aliOssAccessKey:String!
    var aliOssSecretKey:String!
    
    var appStoreId:String!
    
    var umengAppkey:String!
    var shareSDKAppkey:String!
    
    var facebookAppkey:String!
    var facebookAppScrect:String!
    
    var wechatAppkey:String!
    var wechatAppScrect:String!
    
    var qqAppkey:String!
    
    var weiboAppkey:String!
    var weiboAppScrect:String!
    
}

