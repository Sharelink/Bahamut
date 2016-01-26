//
//  UUMsgItem.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

protocol UUMegItemDataSource
{
    var dataSource:[UUMsgItem]{get}
    func loadPreviousMessage() -> Int
}

class UUMsgItem
{
    init()
    {
        frame = UUMessageFrame()
        uimsg = UUMessage()
        dic = [NSObject : AnyObject]()
        msgFrom = .Me
        avatar = ""
    }
    private(set) var dic:[NSObject : AnyObject]!
    private var frame:UUMessageFrame!
    private var uimsg:UUMessage!
    var msgFrame:UUMessageFrame{
        uimsg.setWithDict(dic)
        frame.message = uimsg
        return frame
    }
    
    var previousTime:String!{
        didSet{
            uimsg.minuteOffSetStart(previousTime, end: timeString)
            frame.showTime = uimsg.showDateLabel
        }
    }
    
    var senderId:String!{
        didSet{
            dic.updateValue(senderId, forKey: "strId")
        }
    }
    
    var nick:String!{
        didSet{
            dic.updateValue(nick, forKey: "strName")
        }
    }
    
    var msgFrom:UUMessageFrom{
        didSet{
            dic.updateValue(msgFrom.rawValue, forKey: "from")
        }
    }
    
    var timeString:String!{
        didSet{
            uimsg.minuteOffSetStart(previousTime, end: timeString)
            frame.showTime = uimsg.showDateLabel
            dic.updateValue(timeString, forKey: "strTime")
        }
    }
    
    var time:NSDate{
        return DateHelper.stringToDateTime(timeString.substringToIndex(19))
    }
    
    var avatar:String!{
        didSet{
            if String.isNullOrWhiteSpace(avatar)
            {
                dic.updateValue(ImageAssetsConstants.defaultAvatarPath, forKey: "strIcon")
            }else
            {
                dic.updateValue(avatar, forKey: "strIcon")
            }
            
        }
    }
    
    var msgType:UUMessageType = .Text{
        didSet{
            dic.updateValue(msgType.rawValue, forKey: "type")
        }
    }
    
}

class UUMsgTextItem: UUMsgItem
{
    override init()
    {
        super.init()
        self.msgType = .Text
    }
    
    var message:String!{
        didSet{
            dic.updateValue(message, forKey: "strContent")
        }
    }
}

class UUMsgVoiceItem: UUMsgItem
{
    override init()
    {
        super.init()
        self.msgType = .Voice
    }
    
    var voice:NSData!{
        didSet{
            dic.updateValue(voice, forKey: "voice")
        }
    }
    
    var voiceTimeSec:Int = 0{
        didSet{
            dic.updateValue("\(voiceTimeSec)", forKey: "strVoiceTime")
        }
    }
}

class UUmsgPictureItem: UUMsgItem
{
    override init()
    {
        super.init()
        self.msgType = .Picture
    }
    
    var image:UIImage!{
        didSet{
            dic.updateValue(image, forKey: "picture")
        }
    }
}