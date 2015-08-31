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
            let n = stringName.startIndex.advancedBy(1)
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
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req, callback: { (result, returnStatus) -> Void in
            //TODO: delete
            if 1.description == "1"
            {
                self.testGetLinkedUsers()
                PersistentManager.sharedInstance.refreshCache(ShareLinkUser)
                PersistentManager.sharedInstance.refreshCache(UserLink)
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
                                PersistentManager.sharedInstance.refreshCache(UserLink)
                                PersistentManager.sharedInstance.refreshCache(ShareLinkUser)
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
            user.createTime = userLinked.createTime
            users.append(user)
            userLinks.append(userLinked)
        }
        UserLink.saveObjectOfArray(userLinks)
        ShareLinkUser.saveObjectOfArray(users)
        self.initLinkedUsers()
    }
    
    //MARK: UserTag
    func getMyAllTags() ->[SharelinkTag]
    {
        return PersistentManager.sharedInstance.getAllModelFromCache(SharelinkTag)
    }
    
    //refresh all the tag entities
    func refreshMyAllSharelinkTags(sucCallback:(()->Void)! = nil)
    {
        let req = GetMyAllTagsRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == .OK
            {
                if let tags = result as? SharelinkTags
                {
                    ShareLinkObject.saveObjectOfArray(tags.items)
                    PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }else
            {
                //TODO: delete
                if let tags = result as? SharelinkTags
                {
                    ShareLinkObject.saveObjectOfArray(tags.items)
                    PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }
        })
    }
    
    //refresh all user 's tags i given
    func refreshAllLinkedUserTags(sucCallback:(()->Void)! = nil)
    {
        let req = GetAllLinkedUserTagsRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == .OK
            {
                if let usertags = result as? UserTags
                {
                    ShareLinkObject.saveObjectOfArray(usertags.items)
                    PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }else{
                //TODO: delete test
                if let usertags = result as? UserTags
                {
                    ShareLinkObject.saveObjectOfArray(usertags.items)
                    PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }
        })
    }
    
    func addSharelinkTag(tag:SharelinkTag,sucCallback:(()->Void)! = nil)
    {
        let req = AddNewTagRequest()
        req.tagColor = tag.tagColor
        req.tagName = tag.tagName
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == .OK
            {
                if let newtag = result as? SharelinkTag
                {
                    tag.tagId = newtag.tagId
                    tag.saveModel()
                    PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }else{
                //TODO: delete test
                tag.tagId = NSDate().timeIntervalSince1970.description
                tag.saveModel()
                PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
    
    func getAUsersTags(userId:String) -> [SharelinkTag]
    {
        let result = PersistentManager.sharedInstance.getAllModel(UserTag)
        let ids = result.filter{$0.userId == userId}.map{return $0.tagId!}
        return PersistentManager.sharedInstance.getModels(SharelinkTag.self, idValues: ids)
    }
    
    func getUserTagUsers(tagId:String) -> [ShareLinkUser]
    {
        let userIds = PersistentManager.sharedInstance.getAllModelFromCache(UserTag).filter{$0.tagId == tagId}.map {return $0.userId! }
        return getUsers(userIds)
    }
    
    func updateTag(tag:SharelinkTag,sucCallback:(()->Void)! = nil)
    {
        let req = UpdateTagRequest()
        req.tagName = tag.tagName
        req.tagColor = tag.tagColor
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
        req.willAddTagIds = willAddTags.map{return $0.tagId}
        req.willRemoveTagIds = willRemoveTags.map{return $0.tagId}
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                ShareLinkObject.saveObjectOfArray(willAddTags)
                ShareLinkObject.deleteObjectArray(willRemoveTags)
                if let callback = sucCallback
                {
                    callback()
                    
                }
            }else{
                //TODO: delete test
                ShareLinkObject.saveObjectOfArray(willAddTags)
                ShareLinkObject.deleteObjectArray(willRemoveTags)
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
}