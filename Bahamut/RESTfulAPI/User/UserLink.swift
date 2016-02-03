//
//  UserLink.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import EVReflection

//MARK: Entities
public class AULReturn : EVObject
{
    public class AULink: EVObject
    {
        public var linkId:String!
        public var masterUserId:String!
        public var slaveUserId:String!
        public var status:String!
        public var createTime:String!
    }
    
    public class AUUser : EVObject
    {
        public var userId:String!
        public var nickName:String!
        public var noteName:String!
        public var avatarId:String!
        public var personalVideoId:String!
        public var createTime:String!
        public var motto:String!
    }
    
    public var newLink:AULink!
    public var newUser:AUUser!
}

public enum LinkMessageType:String
{
    case AskLink = "asklink"
    case AcceptAskLink = "acceptlink"
    case NewLinkAccepted = "newLinkAccepted"
}

public class LinkMessage : BahamutObject
{
    public var id:String!
    public var sharelinkerId:String!
    public var sharelinkerNick:String!
    public var type:String!
    public var message:String!
    public var avatar:String!
    public var time:String!
    
    override public func getObjectUniqueIdName() -> String {
        return "id"
    }
}

public extension LinkMessage
{
    public func isAskingLinkMessage() -> Bool
    {
        return LinkMessageType.AskLink.rawValue == self.type
    }
    
    public func isAcceptAskLinkMessage() -> Bool
    {
        return LinkMessageType.AcceptAskLink.rawValue == self.type
    }
    
    public func isNewLinkAccepted()->Bool
    {
        return LinkMessageType.NewLinkAccepted.rawValue == self.type
    }
}

public class UserLink: BahamutObject
{
    public var linkId:String!
    public var masterUserId:String!
    public var slaveUserId:String!
    public var status:String!
    public var createTime:String!
    
    public override func getObjectUniqueIdName() -> String {
        return "linkId"
    }
    
    public var createTimeOfDate:NSDate!{
        return DateHelper.stringToDateTime(createTime)
    }
}

public enum UserLinkStatus : Int
{
    //master side
    case Asking = 1
    case Linked = 2
    case DeLinked = 3
    //slaver side
    case WaitingConfirm = 4
    case Rejected = 5
}

//MARK: Requests

public class AcceptAskingLinkRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .POST
        self.api = "/UserLinks"
    }
    
    public var sharelinkerId:String!{
        didSet{
            self.api = "/UserLinks/\(sharelinkerId)"
        }
    }
    
    public var noteName:String!{
        didSet{
            self.paramenters["noteName"] = noteName
        }
    }
}

public class DeleteLinkMessagesRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .DELETE
        self.api = "/UserLinks/LinkMessages"
    }
}

public class GetLinkMessagesRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .GET
        self.api = "/UserLinks/LinkMessages"
    }
}

public class AddUserLinkRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .POST
        self.api = "/UserLinks"
    }
    
    public var otherUserId:String!{
        didSet{
            self.paramenters["otherUserId"] = otherUserId
        }
    }
    
    public var message:String!{
        didSet{
            self.paramenters["msg"] = message
        }
    }
}

/*
GET /UserLinks : get my all userlinks
*/
public class GetUserLinksRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .GET
        self.api = "/UserLinks"
    }
}

public class UpdateLinkedUserNoteNameRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/UserLinks/NoteName"
    }
    
    public var newNoteName:String!{
        didSet{
            self.paramenters["newNoteName"] = newNoteName
        }
    }
    
    public var userId:String!{
        didSet{
            self.paramenters["userId"] = userId
        }
    }
}

/*
PUT /UserLinks (status,userId): update my userlink status with other people
*/
public class UpdateUserLinkStatusWithOtherRequest: ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/UserLinks"
    }
    
    public var status:String!{
        didSet{
            self.paramenters["status"] = status
        }
    }
    
    public var userId:String!{
        didSet{
            self.paramenters["userId"] = userId
        }
    }

}

