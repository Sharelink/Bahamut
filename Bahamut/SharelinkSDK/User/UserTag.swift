//
//  UserTag.swift
//  Sharelink
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

public struct SharelinkTagConstant
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

public extension SharelinkTag
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
    
    public func isSystemTag() -> Bool
    {
        return isDomainOf(SharelinkTagConstant.TAG_DOMAIN_SYSTEM)
    }
    
    public func isCustomTag() -> Bool
    {
        return  isDomainOf(SharelinkTagConstant.TAG_DOMAIN_CUSTOM)
    }
    
    public func isResharelessTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_NORESHARE)
    }
    
    public func isKeywordTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_KEYWORD)
    }
    
    public func isGeoTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_GEO)
    }
    
    public func isSharelinkerTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_SHARELINKER)
    }
    
    public func isFeedbackTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_FEEDBACK)
    }
    
    public func isBroadcastTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_BROADCAST)
    }
    
    public func isPrivateTag() -> Bool
    {
        return isTypeOf(SharelinkTagConstant.TAG_TYPE_PRIVATE)
    }
}

public class SendTagModel:BahamutObject
{
    public var name:String!
    public var type:String!
    public var data:String!
}

public class SharelinkTag : BahamutObject
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
    
    public func getTagString() -> String
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

public class UserSharelinkTags : BahamutObject
{
    public var userId:String!
    public var tags:[SharelinkTag]!
    public override func getObjectUniqueIdName() -> String {
        return "userId"
    }
}

/*
GET: /SharelinkTags/ : Get user's all tags from server,return SharelinkTags
*/
public class GetMyAllTagsRequest: ShareLinkSDKRequestBase
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
public class AddNewTagRequest: ShareLinkSDKRequestBase
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
    
    public var isFocus:String!{
        didSet{
            self.paramenters["isFocus"] = isFocus
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
PUT /SharelinkTags/{tagId} ({tagName,tagColor,isFocus,data): update tag name property
*/
public class UpdateTagRequest:ShareLinkSDKRequestBase
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
public class RemoveTagsRequest: ShareLinkSDKRequestBase
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
public class GetLinkedUserTagsRequest: ShareLinkSDKRequestBase
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