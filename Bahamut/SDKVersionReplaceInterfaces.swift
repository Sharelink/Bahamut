//
//  SDKVersionReplaceInterfaces.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/26.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
//MARK: SDK_VERSION

#if SDK_VERSION
    protocol QupaiSDKDelegate{}
    
    class MobClick
    {
        static func beginLogPageView(a:String){}
        static func endLogPageView(a:String){}
        static func event(a:String){}
        static func profileSignOff(){}
        static func profileSignInWithPUID(a:String){}
    }
    
    extension SRCService
    {
        func loadDevelopingPlugins()
        {
            if let srcDirUrl = NSBundle.mainBundle().URLForResource("src", withExtension: nil)
            {
                self.loadCustomPlugins(srcDirUrl)
            }
        }
    }
    
#endif