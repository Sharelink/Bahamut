//
//  UserTag.swift
//  Sharelink
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

public struct SharelinkThemeConstant
{
    public static let TAG_DOMAIN_CUSTOM = "custom:";
    public static let TAG_DOMAIN_SYSTEM = "system:";

    public static let TAG_TYPE_KEYWORD = "keyword:";
    public static let TAG_TYPE_GEO = "geo:";
    public static let TAG_TYPE_SHARELINKER = "sharelinker:";

    public static let TAG_TYPE_FEEDBACK = "feedback:";
    public static let TAG_TYPE_BROADCAST = "broadcast:";
    public static let TAG_TYPE_PRIVATE = "private:";
    public static let TAG_TYPE_NORESHARE = "reshareless:"
}

public extension SharelinkTheme
{
    
    public func isTypeOf(type:String) -> Bool
    {
        if let tagType = self.type
        {
            return type == tagType
        }
        return false
    }
    
    public func isDomainOf(domain:String) -> Bool
    {
        if let tagDomain = self.domain
        {
            return domain == tagDomain
        }
        return false
    }
    
    public func isSystemTheme() -> Bool
    {
        return isDomainOf(SharelinkThemeConstant.TAG_DOMAIN_SYSTEM)
    }
    
    public func isCustomTheme() -> Bool
    {
        return  isDomainOf(SharelinkThemeConstant.TAG_DOMAIN_CUSTOM)
    }
    
    public func isResharelessTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_NORESHARE)
    }
    
    public func isKeywordTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_KEYWORD)
    }
    
    public func isGeoTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_GEO)
    }
    
    public func isSharelinkerTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_SHARELINKER)
    }
    
    public func isFeedbackTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_FEEDBACK)
    }
    
    public func isBroadcastTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_BROADCAST)
    }
    
    public func isPrivateTheme() -> Bool
    {
        return isTypeOf(SharelinkThemeConstant.TAG_TYPE_PRIVATE)
    }
}

public class SendTagModel:BahamutObject
{
    public var name:String!
    public var type:String!
    public var data:String!
}

public class SharelinkTheme : BahamutObject
{
    public var tagId:String!
    public var tagName:String!
    public var tagColor:String!
    public var data:String!
    public var type:String!
    public var domain:String!
    public var isFocus:String!
    public var showToLinkers:String!
    public var time:String!
    
    public func getThemeString() -> String
    {
        let st = SendTagModel()
        st.name = tagName
        st.type = self.type
        st.data = self.data
        return st.toJsonString()
    }
    
    public override func getObjectUniqueIdName() -> String {
        return "tagId"
    }
}

public class SharelinkerThemes : BahamutObject
{
    public var userId:String!
    public var tags:[SharelinkTheme]!
    public override func getObjectUniqueIdName() -> String {
        return "userId"
    }
}

/*
GET: /SharelinkTags/ : Get user's all tags from server,return SharelinkTags
*/
public class GetMyAllTagsRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .GET
        self.api = "/SharelinkTags"
    }
}

/*
POST /SharelinkTags (tagName,tagColor,data,isFocus):add a new user tag to my tags collection
*/
public class AddNewTagRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .POST
        self.api = "/SharelinkTags"
    }
    
    public var tagName:String!{
        didSet{
            self.paramenters["tagName"] = tagName
        }
    }
    
    public var tagColor:String!{
        didSet{
            self.paramenters["tagColor"] = tagColor
        }
    }
    
    public var data:String!{
        didSet{
            self.paramenters["data"] = data
        }
    }
    
    public var isFocus:Bool = true{
        didSet{
            self.paramenters["isFocus"] = isFocus ? "true" : "false"
        }
    }
    
    public var isShowToLinkers:Bool = true{
        didSet{
            self.paramenters["isShowToLinkers"] = isShowToLinkers ? "true" : "false"
        }
    }
    
    public var notifyFriends:Bool = true{
        didSet{
            self.paramenters["notifyFriends"] = notifyFriends ? "true" : "false"
        }
    }
    
    public var type:String!{
        didSet{
            self.paramenters["type"] = type
        }
    }
}

/*
PUT /SharelinkTags/{tagId} ({tagName,tagColor,isFocus,data): update tag name property
*/
public class UpdateTagRequest:BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/SharelinkTags"
    }
    
    public var tagId:String!{
        didSet{
            self.api = "/SharelinkTags/\(tagId)"
            
        }
    }
    
    public var data:String!{
        didSet{
            self.paramenters["data"] = data
        }
    }
    
    public var isFocus:String!{
        didSet{
            self.paramenters["isFocus"] = isFocus
        }
    }
    
    public var tagName:String!{
        didSet{
            self.paramenters["tagName"] = tagName
        }
    }
    
    public var tagColor:String!{
        didSet{
            self.paramenters["tagColor"] = tagColor
        }
    }
    
    public var isShowToLinkers:String!{
        didSet{
            self.paramenters["isShowToLinkers"] = isShowToLinkers
        }
    }
    
    public var type:String!{
        didSet{
            self.paramenters["type"] = type
        }
    }
}

/*
DELETE /SharelinkTags (tagIds) : delete the tags,and all the user has link to this tag will be dislink
*/
public class RemoveTagsRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .DELETE
        self.api = "/SharelinkTags"
    }
    
    public var tagIds:[String]!{
        didSet{
            self.paramenters["tagIds"] = tagIds.joinWithSeparator("#")
        }
    }
}

/*
GET: /UserTags/{userId} : Get linked user's all tags from server
*/
public class GetLinkedUserTagsRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .GET
        self.api = "/UserTags"
    }
    
    public var userId:String!{
        didSet{
            self.api = "/UserTags/\(userId)"
        }
    }
}

public class GetHotThemesRequest : BahamutRFRequestBase
{
    public class HotThemes:BahamutObject
    {
        var themes:[String]!
    }
    
    public override init() {
        super.init()
        self.method = .GET
        self.api = "/SharelinkThemes/HotThemes"
    }
}