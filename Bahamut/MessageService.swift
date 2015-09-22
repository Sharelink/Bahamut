
//
//  ReplyService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class UserMessageListItem
{
    var userId:String!
    var shareId:String!
    var message:String!
    var time:NSDate!
}

class MessageService:NSNotificationCenter,ServiceProtocol
{
    @objc static var ServiceName:String {return "MessageService"}
    @objc func appStartInit() {}
    
    @objc func userLoginInit(userId: String) {}
    
    static let messageListUpdated = "messageListUpdated"
    
    private(set) var messageList:[UserMessageListItem]!
    
    func getShareIdNotReadMessageCount(shareId:String) -> UInt32
    {
        return 0
    }
}