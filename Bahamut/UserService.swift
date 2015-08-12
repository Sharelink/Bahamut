//
//  UserService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/31.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class UserService: ServiceProtocol
{
    @objc static var ServiceName:String{return "user service"}
    @objc func initService()
    {
        initLinkedUsers()
    }
    
    private(set) lazy var myUserId:String!={
        return NSUserDefaults.standardUserDefaults().valueForKey("userId") as? String
    }()
    private(set) var myLinkedUsers:[ShareLinkUser]!
    
    private func initLinkedUsers()
    {
        myLinkedUsers = getLinkedUsers()
    }
    
    func getUsers(userIds:[String]) -> [ShareLinkUser]
    {
        //Read from cache
        return PersistentManager.sharedInstance.getModels(ShareLinkUser.self, idValues: userIds)
    }
    
    func getUser(userId:String, serverNewestCallback:((newestUser:ShareLinkUser!, msg:String!)->Void)! = nil) -> ShareLinkUser?
    {
        //Read from cache
        let user = PersistentManager.sharedInstance.getModel(ShareLinkUser.self, idValue: userId)
        
        //request server
        let req = GetShareLinkUsersRequest()
        req.userIds = [userId]
        ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(req, callback: { (result, returnStatus) -> Void in
            var newestUser:ShareLinkUser!
            var msg:String! = nil
            if returnStatus.returnCode != ReturnCode.OK
            {
                newestUser = nil
                msg = returnStatus.message
            }else if let shareLinkUsers:ShareLinkUsers = result as? ShareLinkUsers
            {
                newestUser = shareLinkUsers.items.filter{$0.userId == userId}[0]
            }
            if let callback = serverNewestCallback
            {
                callback(newestUser: newestUser, msg: msg)
            }
        })
        return user
    }
    
    func refreshMyLinkedUsers(refreshCallback:(isSuc:Bool, msg:String!)->Void)
    {
        let req = GetUserLinksRequest()
        ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(req, callback: { (result, returnStatus) -> Void in
            //TODO: delete 
            if 1.description == "1"
            {
                self.testGetLinkedUsers()
                
                refreshCallback(isSuc: true, msg: nil)
                return
            }
            
            if returnStatus.returnCode == ReturnCode.OK
            {
                if let userLinks:UserLinks = result as? UserLinks
                {
                    let userIds = userLinks.items.map{ user -> String in
                        return user.slaveUserId
                    }
                    let usersReq = GetShareLinkUsersRequest()
                    usersReq.userIds = userIds
                    ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(usersReq, callback: { (result, returnStatus) -> Void in
                        if returnStatus.returnCode == ReturnCode.OK
                        {
                            if let users:ShareLinkUsers = result as? ShareLinkUsers
                            {
                                UserLink.saveObjectOfArray(userLinks.items)
                                ShareLinkUser.saveObjectOfArray(users.items)
                                self.initLinkedUsers()
                                refreshCallback(isSuc: true, msg: "")
                            }else{
                                refreshCallback(isSuc: false, msg: returnStatus.message)
                            }
                        }else{
                            refreshCallback(isSuc: false, msg: returnStatus.message)
                        }
                    })
                }else{
                    refreshCallback(isSuc: false, msg: returnStatus.message)
                }
            }else
            {
                refreshCallback(isSuc: false, msg: returnStatus.message)
            }
        })
    }
    
    private func getLinkedUsers() -> [ShareLinkUser]
    {
        let myLinkedUserLink = PersistentManager.sharedInstance.getAllModel(UserLink)
        let userIds = myLinkedUserLink.filter{$0.masterUserId == self.myUserId}.map{ link -> String in
            return link.slaveUserId
        }
        return getUsers(userIds)
    }
    
    func setProfile(properties:[String:String],setProfileCallback:((isSuc:Bool,msg:String!)->Void)! = nil)
    {
        let req = UpdateShareLinkUserProfileRequest()
        req.nickName = properties["nickName"]
        req.signText = properties["signText"]
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            var isSuc:Bool = false
            var msg:String! = nil
            if returnStatus.returnCode == ReturnCode.OK
            {
                isSuc = true
            }else
            {
                msg = returnStatus.message
            }
            if let callback = setProfileCallback
            {
                callback(isSuc: isSuc, msg: msg)
            }
        })
    }
    
    func checkUsernameAvailable(username:String,checkCallback:(isAvailable:Bool,msg:String!)-> Void)
    {
        let req = GetShareLinkUsersRequest()
        req.userName = username
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                if let user = result as? ShareLinkUser
                {
                    checkCallback(isAvailable: false,msg: "user name has been registed")
                }else
                {
                    checkCallback(isAvailable: true, msg: "")
                }
            }
        })
    }
    
    func testGetLinkedUsers()
    {
        var users = [ShareLinkUser]()
        var userLinks = [UserLink]()
        for userId in (147258..<147270)
        {
            var user = ShareLinkUser()
            var userLinked = UserLink()
            userLinked.linkId = "\(147258)_\(userId)"
            userLinked.masterUserId = "147258"
            userLinked.slaveUserId = "\(userId)"
            userLinked.status = UserLinkStatus.Linked.rawValue
            let randDate = NSDate(timeIntervalSinceNow: Double(arc4random() % (3600 * 24 * 14)))
            userLinked.createTime = DateHelper.dateToString(randDate)
            user.userId = "\(userId)"
            user.nickName = userId.description == "147258" ? "The Different YY" : "nick:\(userId)"
            user.headIconId = userId.description == "147258" ? "YY" : "defaultHeadIcon"
            user.personalVideoId = "\(userId)"
            user.signText = "the different \(userId)"
            users.append(user)
            userLinks.append(userLinked)
        }
        UserLink.saveObjectOfArray(userLinks)
        ShareLinkUser.saveObjectOfArray(users)
        self.initLinkedUsers()
    }
}