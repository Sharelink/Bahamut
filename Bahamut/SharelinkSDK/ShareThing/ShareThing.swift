//
//  ShareThing.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire

//MARK: Entities
public enum ShareThingType:String
{
    case shareTypePrefix = "share:"
    case shareFilm = "share:film"
    case messageTypePrefix = "message:"
    case addTagMessage = "message:add_tag"
    case focusTagMessage = "message:focus_tag"
    case customMessage = "message:custom"
    case textMessage = "message:text"
}

public extension ShareThing
{
    public func isUserShare() -> Bool
    {
        return String.isNullOrWhiteSpace(self.shareType) == false && self.shareType.hasPrefix(ShareThingType.shareTypePrefix.rawValue)
    }
    
    public func isMessageShare() -> Bool
    {
        return String.isNullOrWhiteSpace(self.shareType) == false && self.shareType.hasPrefix(ShareThingType.messageTypePrefix.rawValue)
    }
    
    public func isShareFilm() -> Bool
    {
        return ShareThingType.shareFilm.rawValue == self.shareType
    }
    
    public func isAddTagMessage() -> Bool
    {
        return ShareThingType.addTagMessage.rawValue == self.shareType
    }
    
    public func isFocusTagMessage() -> Bool
    {
        return ShareThingType.focusTagMessage.rawValue == self.shareType
    }
    
    public func isTextMessage() -> Bool
    {
        return ShareThingType.textMessage.rawValue == self.shareType
    }
    
    public func canReshare() -> Bool
    {
        return "true" == self.reshareable
    }
}

public class ShareThing: ShareLinkObject
{
    public var shareId:String!
    public var pShareId:String!
    public var userId:String!
    public var userNick:String!
    public var avatarId:String!
    public var shareTime:String!
    public var shareType:String!
    public var message:String!
    public var shareContent:String!
    public var voteUsers:[String]!
    public var forTags:[String]!
    public var reshareable:String!
    
    public override func getObjectUniqueIdName() -> String {
        return "shareId"
    }
    
    public var shareTimeOfDate:NSDate!{
        if let date = DateHelper.stringToDateTime(shareTime)
        {
            return date
        }
        return NSDate()
    }
}

public class ShareUpdatedMessage : ShareLinkObject
{
    public var shareId:String!
    public var time:String!
}

//MARK: Requests
/*
page: page of the results,0 means return all record
pageCount: result num of one page
newerThanThisTime: return the newest modified sharethings after this time,except this time,the first one of return values is close to this time,conflict with olderThanThisTime property，last set effective
olderThanThisTime: return the sharethings before this time,except this time,the first one of return values is close to this time,conflict with newerThanThisTime property，last set effective the
shareIds: filter,defalut nil
GET /ShareThings : get user shares,get my share default,if set the userId property,get the share of userId user, with shareIds parameter,will only get the shares which in the shareIds
*/
public class GetShareThingsRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.GET
        self.api = "/ShareThings"
    }
    
    public var page:Int! = 0{
        didSet{
            self.paramenters.updateValue("\(page)", forKey: "page")
        }
    }
    
    public var pageCount:Int! = 20{
        didSet{
            self.paramenters.updateValue("\(pageCount)", forKey: "pageCount")
        }
    }
    
    public var beginTime:NSDate! = nil{
        didSet{
            self.paramenters.updateValue(DateHelper.toDateTimeString(beginTime), forKey: "beginTime")
        }
    }
    
    public var endTime:NSDate! = nil{
        didSet{
            self.paramenters.updateValue(DateHelper.toDateTimeString(endTime), forKey: "endTime")
        }
    }

}

/*
POST /ShareThings (pshareid,sharetitle,sharetype,shareContent) : post a new share,if pshareid equals 0, means not a reshare action,
                                                                 when upload file or other thing ,it have to post a FinishNewShareThingRequest
*/
public class AddNewShareThingRequest : GetShareThingsRequest
{
    public override init() {
        super.init()
        self.method = Method.POST
        self.api = "/ShareThings"
    }
    
    public var shareType:String!{
        didSet{
            self.paramenters.updateValue(shareType, forKey: "shareType")
        }
    }
    
    public var shareContent:String!{
        didSet{
            self.paramenters.updateValue(shareContent, forKey: "shareContent")
        }
    }
    
    public var tags:[SharelinkTag]!{
        didSet{
            let v = (tags.map{ ($0.getTagString() as NSString).base64String() }.joinWithSeparator("#"))
            let reshareable = tags.contains{$0.isResharelessTag()}
            self.paramenters.updateValue(reshareable ? "false" : "true", forKey: "reshareable")
            self.paramenters.updateValue(v, forKey: "tags")
        }
    }
    
    public var message:String!{
        didSet{
            self.paramenters.updateValue(message, forKey: "message")
        }
    }
}

/*
POST /ShareThings/Finished/{shareId} //make share post finish,only post this request,the add new share process was completed
*/
public class FinishNewShareThingRequest : GetShareThingsRequest
{
    public override init() {
        super.init()
        self.method = Method.POST
        self.api = "/ShareThings"
    }
    
    public var shareId:String!{
        didSet{
            self.api = "/ShareThings/Finished/\(shareId)"
        }
    }
    
    public var taskSuccess:Bool = false{
        didSet{
            self.paramenters.updateValue(taskSuccess ? "true":"false", forKey: "taskSuccess")
        }
    }
}

/*
POST /ShareThings/Reshare/{pShareId} (newTags,message) //reshare share thing
*/
public class ReShareRequest:ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.POST
        self.api = "/ShareThings/Reshare"
    }
    
    public var pShareId:String!{
        didSet{
            if let id = pShareId
            {
                self.api = "/ShareThings/Reshare/\(id)"
            }
            
        }
    }
    
    public var message:String!{
        didSet{
            self.paramenters.updateValue(message, forKey: "message")
        }
    }
    
    public var tags:[SharelinkTag]!{
        didSet{
            let v = (tags.map{ ($0.getTagString() as NSString).base64String() }.joinWithSeparator("#"))
            let reshareable = tags.contains{$0.isResharelessTag()}
            self.paramenters.updateValue(reshareable ? "false" : "true", forKey: "reshareable")
            self.paramenters.updateValue(v, forKey: "tags")
        }
    }
}


/*
GET /ShareThings/ShareIds : return sharethings with id filter
*/
public class GetShareOfShareIdsRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.GET
        self.api = "/ShareThings/ShareIds"
    }
    
    public var shareIds:[String]! = nil{
        didSet{
            self.paramenters.updateValue(shareIds.joinWithSeparator("#"), forKey: "shareIds")
        }
    }
    
}

/*
GET /ShareThings/Updated : return updated sharethings ids
*/
public class GetShareUpdatedMessageRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.GET
        self.api = "/ShareThings/Updated"
    }
}

/*
DELETE /ShareThings/Updated : clear update message box
*/
public class ClearShareUpdatedMessageRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = Method.DELETE
        self.api = "/ShareThings/Updated"
    }
}