//
//  ReplyService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class ReplyService: ServiceProtocol
{
    @objc static var ServiceName:String {return "reply service"}
    @objc func initService() {
        
    }
    
    func getShareIdNotReadMessageCount(shareId:String) -> UInt32
    {
        return arc4random() % 20
    }
}