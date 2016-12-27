//
//  BahamutRFKit.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

//MARK: BahamutRFKit
class BahamutRFKit:NSNotificationCenter
{
    static let onTokenInvalidated = "onTokenInvalidated"
    
    static var appkey = "no_key"
    static var appVersion:String = "1.0"
    static var appVersionCode:Int = 1
    static var platform:String = "ios"
    
    var userInfos = [String:AnyObject?]()
    
    private(set) var clients:[String:ClientProtocal] = [String:ClientProtocal]()
    
    static let sharedInstance: BahamutRFKit = {
        return BahamutRFKit()
    }()
    
    func useClient(client:ClientProtocal,clientKey:String) -> ClientProtocal {
        clients.updateValue(client, forKey: clientKey)
        return client
    }
    
    func startClients()
    {
        for client in clients.values
        {
            client.setClientStart()
        }
    }
    
    func closeClients()
    {
        for client in clients.values
        {
            client.setClientClose()
        }
        clients.removeAll()
    }
}
