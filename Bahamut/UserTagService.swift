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
        client.execute(req){ (result:SLResult<[SharelinkTag]>) -> Void in
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
    
    func addSharelinkTag(tag:SharelinkTag,sucCallback:(()->Void)! = nil)
    {
        let req = AddNewTagRequest()
        req.tagColor = tag.tagColor
        req.tagName = tag.tagName
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<SharelinkTag>) -> Void in
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
        client.execute(req, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
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
        var r:ShareLinkSDKRequestBase! = nil
        if tag.tagColor != nil
        {
            let req = UpdateTagColorRequest()
            req.tagColor = tag.tagColor
            req.tagId = tag.tagId
            r = req
        }else if tag.tagName != nil
        {
            let req = UpdateTagNameRequest()
            req.tagName = tag.tagName
            req.tagId = tag.tagId
            r = req
        }else if let callback = sucCallback{
            callback()
        }
        
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(r!, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                tag.saveModel()
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
}