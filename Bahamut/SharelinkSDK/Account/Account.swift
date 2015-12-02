//
//  Account.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/3.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: Entities
public class Account : SharelinkObject
{
    public var accountName:String!
    public var accountId:String!
    public var createTime:String!
    public var email:String!
    public var mobile:String!
    public var name:String!
    public var birthdate:NSNumber!
    
    public override func getObjectUniqueIdName() -> String {
        return "accountId"
    }
    
    public var createTimeOfDate:NSDate!{
        return DateHelper.stringToDateTime(createTime)
    }
}

//MARK: Requests
/*
GET /Accounts : return my account information
*/
public class GetAccountRequest: ShareLinkSDKRequestBase
{
    public override init()
    {
        super.init()
        self.method = .GET
        self.api = "/Accounts"
    }

}

/*
PUT /Accounts : update my account properties
*/
public class UpdateAccountNameRequest: ShareLinkSDKRequestBase
{
    public override init()
    {
        super.init()
        self.method = .PUT
        self.api = "/Accounts/Name"
    }
    
    public var name:String!{
        didSet{
            self.paramenters["name"] = name
        }
    }

}

/*
PUT /Accounts : update my account properties
*/
public class UpdateAccountBirthdateRequest: ShareLinkSDKRequestBase
{
    public override init()
    {
        super.init()
        self.method = .PUT
        self.api = "/Accounts/BirthDate"
    }
    
    public var birthdate:NSDate!{
        didSet{
            self.paramenters["birthdate"] = DateHelper.toDateTimeString(birthdate)
        }
    }
    
}


/*
PUT /Accounts/Password (oldPassword,newPassword) : change bahamut account password
*/
public class ChangeAccountPasswordRequest : ShareLinkSDKRequestBase
{
    public override init() {
        super.init()
        self.method = .PUT
        self.api = "/Accounts/Password"
    }
    
    public var oldPassword:String!{
        didSet{
            self.paramenters["oldPassword"] = oldPassword
        }
    }
    
    public var newPassword:String!{
        didSet{
            self.paramenters["newPassword"] = newPassword
        }
    }
    
}