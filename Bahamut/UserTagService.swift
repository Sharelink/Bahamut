//
//  UserSharelinkTagService.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

public class UserTagService : ServiceProtocol
{
    @objc static var ServiceName:String{return "UserTag Service"}
    @objc func initService()
    {
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
        client?.execute(req){ (result:SLResult<[SharelinkTag]>) -> Void in
            if result.statusCode == .OK
            {
                if let tags = result.returnObject
                {
                    ShareLinkObject.saveObjectOfArray(tags)
                    PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                    if let callback = sucCallback
                    {
                        callback()
                    }
                }
            }
        }
    }
    
    //refresh all user 's tags i given
    func refreshAllLinkedUserTags(sucCallback:(()->Void)! = nil)
    {
        let req = GetAllLinkedUserTagsRequest()
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result:SLResult<UserSharelinkTags>) -> Void in
            if result.statusCode == .OK
            {
                if let usertags = result.returnObject
                {
                    usertags.saveModel()
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
        client?.execute(req, callback: { (result:SLResult<SharelinkTag>) -> Void in
            if result.statusCode == .OK
            {
                if let newtag = result.returnObject
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
        let result = PersistentManager.sharedInstance.getModel(UserSharelinkTags.self, idValue: userId)
        return result?.tags ?? [SharelinkTag]()
    }
    
    func getUserIdsHaveThisTagOfId(tagId:String) -> [String]
    {
        if let tag = PersistentManager.sharedInstance.getModel(SharelinkTag.self, idValue: tagId)
        {
            return getUserIdsHaveThisTagOfTagName(tag.tagName!)
        }
        return [String]()
    }
    
    func getUserIdsHaveThisTagOfTagName(tagName:String) -> [String]
    {
        let usertags = PersistentManager.sharedInstance.getAllModelFromCache(UserSharelinkTags)
        let userIds = usertags.filter{$0.tags.contains{$0.tagName == tagName}}.map{$0.userId!}
        return userIds
    }
    
    func removeMyTags(tags:[SharelinkTag],sucCallback:(()->Void)! = nil)
    {
        let req = RemoveTagsRequest()
        req.tagIds = tags.map{$0.tagId}
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                PersistentManager.sharedInstance.removeModels(tags)
                if let callback = sucCallback
                {
                    callback()
                }
            }else{
                //TODO: delete test
                PersistentManager.sharedInstance.removeModels(tags)
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
    
    func updateTag(tag:SharelinkTag,sucCallback:(()->Void)! = nil)
    {
        let req = UpdateTagRequest()
        req.tagName = tag.tagName
        req.tagColor = tag.tagColor
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client?.execute(req, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
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
}