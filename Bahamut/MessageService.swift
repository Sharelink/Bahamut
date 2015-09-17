
//
//  ReplyService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class MessageService: ServiceProtocol
{
    @objc static var ServiceName:String {return "MessageService"}
    @objc func appStartInit() {
        
        
    }
    
    @objc func userLoginInit(userId: String) {
        
        
    }
    
    func getShareIdNotReadMessageCount(shareId:String) -> UInt32
    {
        return 0
    }
}