//
//  Message.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/9/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire
//MARK: Entities

public enum MessageType:String
{
    case Text = "text"
    case Voice = "voice"
    case Picture = "pic"
}

public class Message: SharelinkObject
{
    public var msgId:String!
    public var senderId:String!
    public var chatId:String!
    public var shareId:String!
    public var msg:String!
    public var time:String!
    public var data:String!
    public var msgType:String!
    
    public override func getObjectUniqueIdName() -> String {
        return "msgId"
    }
    
    public var msgData:NSData!{
        if let dataStr = data
        {
            return NSData(base64String: dataStr)
        }
        return nil
    }
    
    public var timeOfDate:NSDate!{
        if let date = DateHelper.stringToAccurateDate(time)
        {
            return date
        }
        return NSDate()
    }
}

//MARK: Requests
/*
newerThanTime: get the messages that time newer than this messageId
chatId:
GET /Messages/{shareId} : get share messages
*/
public class GetShareMessageRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.GET
        self.api = "/Messages"
    }
    
    public var newerThanTime:NSDate! = nil{
        didSet{
            self.paramenters.updateValue(newerThanTime.toAccurateDateTimeString(), forKey: "newerThanTime")
        }
    }
    
    public var chatId:String!{
        didSet{
			self.api = "/Messages/\(chatId)"
        }
    }

}

/*
GET /Message/New : get all new message from server
*/
public class GetNewMessagesRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.GET
        self.api = "/Messages/New"
    }
}

/*
DELETE /Message/New : notify all new message received
*/
public class NotifyNewMessagesReceivedRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.DELETE
        self.api = "/Messages/New"
    }
}

/*
POST /Message/{shareId} : send a new message to sharelinker of the share
*/
public class SendMessageRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.POST
        self.api = "/Messages"
    }
    
    //No limit request
    public override func getCurrentRequestCount() -> Int32 {
        return 0
    }
    
    public override func getMaxRequestCount() -> Int32 {
        return 1
    }
    
    public override func incRequest() {
    }
    
    public override func decRequest() {
    }
    
    public var time:NSDate!{
        didSet{
            self.paramenters.updateValue(time.toAccurateDateTimeString(), forKey: "time")
        }
    }
    
    public var chatId:String!{
        didSet{
			self.api = "/Messages/\(chatId)"
        }
    }
    
    public var type:String = MessageType.Text.rawValue{
        didSet{
            self.paramenters.updateValue(type, forKey: "type")
        }
    }
    
    public var message:String!{
        didSet{
            self.paramenters.updateValue(message, forKey: "message")
        }
    }
    
    public var messageData:NSData!{
        didSet{
            if messageData != nil
            {
                if let str = messageData.base64String()
                {
                    self.paramenters.updateValue(str, forKey: "messageData")
                }
            }
        }
    }
    
    public var  audienceId:String!{
        didSet{
            self.paramenters.updateValue(audienceId, forKey: "audienceId")
        }
    }
    
    public var shareId:String!{
        didSet{
            self.paramenters.updateValue(shareId, forKey: "shareId")
        }
    }
}