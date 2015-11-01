//
//  UserSharelinkTagService.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import SharelinkSDK

class SharelinkTagSortableObject: Sortable
{
    override func getObjectUniqueIdValue() -> String {
        return tagId
    }
    
    var tagId:String!
    
    func getTag() -> SharelinkTag
    {
        return PersistentManager.sharedInstance.getModel(SharelinkTag.self, idValue: tagId)!
    }

    override func isOrderedBefore(b: Sortable) -> Bool {
        let intervalA = self.compareValue as? NSNumber ?? NSDate().timeIntervalSince1970
        let intervalB = b.compareValue as? NSNumber ?? NSDate().timeIntervalSince1970
        return intervalA.doubleValue > intervalB.doubleValue
    }
}

extension SharelinkTag
{
    func getSortableObject() -> SharelinkTagSortableObject
    {
        if let obj = PersistentManager.sharedInstance.getModel(SharelinkTagSortableObject.self, idValue: self.tagId)
        {
            return obj
        }
        let obj = SharelinkTagSortableObject()
        obj.tagId = self.tagId
        obj.compareValue = self.time == nil ? NSNumber(double: 0) : NSNumber(double: self.time.dateTimeOfAccurateString.timeIntervalSince1970)
        return obj
    }
}

public class SharelinkTagService : NSNotificationCenter, ServiceProtocol
{
    static let TagsUpdated:String = "TagsUpdated"
    @objc static var ServiceName:String{return "SharelinkTagService"}
    
    @objc func userLoginInit(userId: String) {
        self.refreshMyAllSharelinkTags()
    }
    
    func userLogout(userId: String) {
    }
    
    private(set) var tagOfMe:SharelinkTag!
    
    //MARK: My Tag
    func getMyAllTags() ->[SharelinkTag]
    {
        return PersistentManager.sharedInstance.getAllModelFromCache(SharelinkTag)
    }
    
    func getAllCustomTags() -> [SharelinkTag]
    {
        let alltags = getMyAllTags()
        return alltags.filter{ $0.domain == SharelinkTagConstant.TAG_DOMAIN_CUSTOM}
    }
    
    func getAllSystemTags() -> [SharelinkTag]
    {
        let alltags = getMyAllTags()
        return alltags.filter{ $0.domain == SharelinkTagConstant.TAG_DOMAIN_SYSTEM}
    }
    
    //refresh all the tag entities
    func refreshMyAllSharelinkTags()
    {
        let req = GetMyAllTagsRequest()
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req){ (result:SLResult<[SharelinkTag]>) -> Void in
            if let tags = result.returnObject
            {
                self.tagOfMe = tags.filter{$0.isSystemTag() && $0.isSharelinkerTag() && $0.data == "me"}.first
                for tag in tags
                {
                    if tag.isSystemTag()
                    {
                        tag.tagName = NSLocalizedString(tag.tagName, comment: "") ?? tag.tagName
                    }
                }
                ShareLinkObject.saveObjectOfArray(tags)
                PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                self.postNotificationName(SharelinkTagService.TagsUpdated, object: self)
            }
        }
    }
    
    func addSharelinkTag(tag:SharelinkTag,sucCallback:((isSuc:Bool)->Void)! = nil)
    {
        let req = AddNewTagRequest()
        req.tagColor = tag.tagColor
        req.tagName = tag.tagName
        req.isFocus = tag.isFocus
        req.data = tag.data
        req.isShowToLinkers = tag.showToLinkers
        req.type = tag.type
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<SharelinkTag>) -> Void in
            var suc = false
            if let newtag = result.returnObject
            {
                tag.tagId = newtag.tagId
                tag.saveModel()
                PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                suc = true
            }
            if let callback = sucCallback
            {
                callback(isSuc: suc)
            }
        })
    }
    
    func removeMyTags(tags:[SharelinkTag],sucCallback:(()->Void)! = nil)
    {
        let req = RemoveTagsRequest()
        req.tagIds = tags.map{$0.tagId}
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                PersistentManager.sharedInstance.removeModels(tags)
                
                if let callback = sucCallback
                {
                    callback()
                }
            }
            PersistentManager.sharedInstance.refreshCache(SharelinkTag)
        })
    }
    
    func updateTag(tag:SharelinkTag,sucCallback:(()->Void)! = nil)
    {
        let req = UpdateTagRequest()
        req.tagId = tag.tagId
        req.tagName = tag.tagName
        req.tagColor = tag.tagColor
        req.isFocus = tag.isFocus
        req.isShowToLinkers = tag.showToLinkers
        req.type = tag.type
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<ShareLinkObject>) -> Void in
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
    
    //MARK: Linked User Tag
    
    func getUserTags(userId:String,updated:(([SharelinkTag])->Void)!) -> [SharelinkTag]
    {
        let req = GetLinkedUserTagsRequest()
        req.userId = userId
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<UserSharelinkTags>) -> Void in
            if result.statusCode == .OK
            {
                if let newtag = result.returnObject
                {
                    newtag.saveModel()
                    if let callback = updated
                    {
                        callback(newtag.tags)
                    }
                }
            }
        }
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
    

}