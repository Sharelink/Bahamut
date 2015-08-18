//
//  UserService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/31.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreFoundation

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
    
    func getUsersDivideWithLatinLetter(users:[ShareLinkUser]) -> [(String,[ShareLinkUser])]
    {
        var result = [(String,[ShareLinkUser])]()
        var dict = [String:[ShareLinkUser]]()
        for index in 0...25
        {
            let letterInt = 65 + index
            let key = StringHelper.IntToLetterString(letterInt)
            let list = [ShareLinkUser]()
            dict.updateValue(list, forKey: key)
        }
        dict.updateValue([ShareLinkUser](), forKey: "#")
        
        for user in users
        {
            let userNoteName = user.noteName ?? user.nickName
            let nickName:CFMutableStringRef = CFStringCreateMutableCopy(nil, 0, userNoteName);
            CFStringTransform(nickName,nil, kCFStringTransformToLatin, false)
            CFStringTransform(nickName, nil, kCFStringTransformStripDiacritics, false)
            
            let stringName = nickName as String
            let n = advance(stringName.startIndex, 1)
            let prefix = stringName.uppercaseString.substringToIndex(n)
            var list = dict[prefix]
            if list == nil
            {
                list = dict["#"]
            }
            list?.append(user)
            dict.updateValue(list!, forKey: prefix) //if not update ,the list in the dict is point to old list ,not appended list
        }
        
        for item in dict
        {
            if item.1.count > 0
            {
                result.append((item.0,item.1))
            }
        }
        result.sortInPlace { (a, b) -> Bool in
            a.0 < b.0
        }
        return result
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
                if let _ = result as? ShareLinkUser
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
            let user = ShareLinkUser()
            let userLinked = UserLink()
            userLinked.linkId = "\(147258)_\(userId)"
            userLinked.masterUserId = "147258"
            userLinked.slaveUserId = "\(userId)"
            userLinked.status = UserLinkStatus.Linked.rawValue
            let randDate = NSDate(timeIntervalSinceNow: Double(arc4random() % (3600 * 24 * 14)))
            userLinked.createTime = DateHelper.dateToString(randDate)
            user.userId = "\(userId)"
            user.nickName = userId.description == "147258" ? "The Different YY" : "nick:\(userId)"
            user.noteName = ["你好","周广杰","The Dfyy","吊炸天杰少"][Int(arc4random() % 4)]
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
    
    //MARK: UserTag
    func getMyAllUserTags() ->[UserTag]
    {
        return PersistentManager.sharedInstance.getAllModel(UserTag)
    }
    
    func refreshMyAllUserTags(sucCallback:(()->Void)! = nil)
    {
        let req = GetAllUserTagsRequest()
        req.userId = self.myUserId
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == .OK
            {
                if let userTags = result as? UserTags
                {
                    ShareLinkObject.saveObjectOfArray(userTags.items)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }
        })
    }
    
    func getLinkedUserAllTags(userId:String) -> [UserTag]
    {
        let result = PersistentManager.sharedInstance.getAllModelFromCache(UserTag)
        return result.filter{
            if $0.tagUserIds == nil
            {
                return false
            }
            for uId in $0.tagUserIds
            {
                if uId == userId
                {
                    return true
                }
            }
            return false
        }
    }
    
    func getUserTagUsers(tag:UserTag) -> [ShareLinkUser]
    {
        return getUsers(tag.tagUserIds)
    }
    
    func addUserTag(tag:UserTag,sucCallback:(()->Void)! = nil)
    {
        let req = AddNewUserTagRequest()
        req.tagName = tag.tagName
        req.tagColor = tag.tagColor
        req.tagUserIds = tag.tagUserIds
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                if let addedTag = result as? UserTag
                {
                    tag.tagId = addedTag.tagId
                    tag.saveModel()
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
                
            }else{
                //TODO: delete test
                tag.tagId = NSDate().timeIntervalSince1970.description
                tag.saveModel()
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
    
    func updateTag(tag:UserTag,sucCallback:(()->Void)! = nil)
    {
        let req = UpdateTagUsersRequest()
        req.tagName = tag.tagName
        req.tagColor = tag.tagColor
        req.tagUserIds = tag.tagUserIds
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                tag.saveModel()
                if let callback = sucCallback
                {
                    callback()
                }
            }else{
                //TODO: delete test
                tag.tagId = NSDate().timeIntervalSince1970.description
                tag.saveModel()
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
    
    func updateUserTags(userId:String,willAddTags:[UserTag],willRemoveTags:[UserTag],sucCallback:(()->Void)! = nil)
    {
        let req = UpdateUserTagsRequest()
        req.userId = userId
        req.willAddTagIds = willAddTags.map({ (tag) -> String in
            return tag.tagId
        })
        req.willRemoveTagIds = willRemoveTags.map({ (tag) -> String in
            return tag.tagId
        })
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                ShareLinkObject.saveObjectOfArray(willAddTags)
                ShareLinkObject.saveObjectOfArray(willRemoveTags)
                if let callback = sucCallback
                {
                    callback()
                }
            }else{
                //TODO: delete test
                ShareLinkObject.saveObjectOfArray(willAddTags)
                ShareLinkObject.saveObjectOfArray(willRemoveTags)
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
}