//
//  NetworkReachability.swift
//  drawlinegame
//
//  Created by Alex Chow on 2017/7/6.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import Alamofire

class NetworkReachability {
    static private(set) var manager:NetworkReachabilityManager!
    
    static func startListenNetworking() {
        if manager == nil{
            manager = NetworkReachabilityManager(host: "www.baidu.com") ?? NetworkReachabilityManager(host: "www.google.com")
        }
        if manager?.listener == nil{
            manager?.listener = { status in }
            manager?.startListening()
        }
    }
    
    static func stopListenNetworking(){
        manager?.stopListening()
    }
    
    static var isReachable:Bool{
        return manager?.isReachable ?? false
    }
}
