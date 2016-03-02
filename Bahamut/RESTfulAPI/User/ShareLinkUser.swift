//
//  User.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: Entities
public class Sharelinker : BahamutObject
{
    public var userId:String!
    public var nickName:String!
    public var noteName:String!
    public var avatarId:String!
    public var personalVideoId:String!
    public var createTime:String!
    public var motto:String!
    public var level:NSNumber!
    public var levelScore:NSNumber!
    public var tags:[String]! //REMOVE THE WARMNING,THIS PROPERTY IS REMOVED FROM SERVER
    
    public override func getObjectUniqueIdName() -> String {
        return "userId"
    }
    
    public var createTimeOfDate:NSDate!{
        return DateHelper.stringToDateTime(createTime)
    }
}

//MARK: Requests

/*
userIds:filter
GET /Sharelinkers : if not set the property userIds,return all my connnected users,the 1st is myself; set the userIds will return the user info of userIds
*/
public class GetSharelinkersRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .GET
        self.api = "/Sharelinkers"
    }
    
    public var userIds:[String]!{
        didSet{
            
            self.paramenters.updateValue(userIds.joinWithSeparator("#"), forKey: "userIds")
        }
    }
}

/*
PUT /Sharelinkers/NickName (nickName) : update my user profile property
*/
public class UpdateSharelinkerProfileNickNameRequest  : BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/Sharelinkers/NickName"
    }
    
    public var nickName:String!{
        didSet{
            self.paramenters["nickName"] = nickName
        }
    }
    
}

/*
PUT /Sharelinkers/Avatar (newAvatarId) : update my user profile property
*/
public class UpdateAvatarRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/Sharelinkers/Avatar"
    }
    
    public var newAvatarId:String!{
        didSet{
            self.paramenters["newAvatarId"] = newAvatarId
        }
    }
}

/*
PUT /Sharelinkers/ProfileVideo (newProfileVideoId) : update my user profile property
*/
public class UpdateProfileVideoRequest: BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/Sharelinkers/ProfileVideo"
    }
    
    public var newProfileVideoId:String!{
        didSet{
            self.paramenters["newProfileVideoId"] = newProfileVideoId
        }
    }
}

/*
PUT /Sharelinkers (nickName,motto) : update my user profile property
*/
public class UpdateSharelinkerProfileMottoRequest : BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/Sharelinkers/Motto"
    }
    
    public var motto:String!{
        didSet{
            self.paramenters["motto"] = motto
        }
    }
    
}

/*
POST /NewSharelinkUsers (nickName)
*/
public class RegistNewSharelinkUserRequest : BahamutRFRequestBase
{
    public override init() {
        super.init()
        self.method = .POST
        self.api = "/NewSharelinkers"
    }
    
    public var region:String!{
        didSet{
            self.paramenters["region"] = region
        }
    }
    
    public var nickName:String!{
        didSet{
            self.paramenters["nickName"] = nickName
        }
    }
    
    public var motto:String!{
        didSet{
            self.paramenters["motto"] = motto
        }
    }
    
    public var appkey:String!{
        didSet{
            self.paramenters["appkey"] = appkey
        }
    }
    public var accountId:String!{
        didSet{
            self.paramenters["accountId"] = accountId
        }
    }
    
    public var accessToken:String!{
        didSet{
            self.paramenters["accessToken"] = accessToken
        }
    }
}

