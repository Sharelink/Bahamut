//
//  UserSharelinkTagService.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: sortable
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

//MARK: tag name for show
extension SharelinkTag
{
    func getShowName() -> String
    {
        var prefix = ""
        let suffix = ""
        if self.isSystemTag()
        {
            if self.isPrivateTag()
            {
                prefix = "👤"
            }else if self.isResharelessTag()
            {
                prefix = "🚫"
            }else if self.isBroadcastTag()
            {
                prefix = "🗣"
            }else if self.isFeedbackTag()
            {
                prefix = "ℹ️"
            }
        }else if self.isCustomTag()
        {
            if self.isSharelinkerTag()
            {
                let noteName = ServiceContainer.getService(UserService).getUserNoteName(self.data)
                return "🙂\(noteName)"
            }else if self.isGeoTag()
            {
                prefix = "📍"
            }else if self.isKeywordTag()
            {
                prefix = "📎"
            }
        }
        return "\(prefix)\(self.tagName)\(suffix)";
    }
    
    func getEditingName() -> String
    {
        return self.tagName ?? ""
    }
}

//MARK: SharelinkTagService

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
    
    func isTagExists(tagData:String) -> Bool
    {
        return self.getAllCustomTags().contains{$0.data == tagData}
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
                newtag.saveModel()
                PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                suc = true
                self.postNotificationName(SharelinkTagService.TagsUpdated, object: self)
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
                self.postNotificationName(SharelinkTagService.TagsUpdated, object: self)
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
        req.tagId = tag.tagId
        req.tagName = tag.tagName
        req.tagColor = tag.tagColor
        req.isFocus = tag.isFocus
        req.isShowToLinkers = tag.showToLinkers
        req.type = tag.type
        req.data = tag.data
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                tag.saveModel()
                PersistentManager.sharedInstance.refreshCache(SharelinkTag)
                self.postNotificationName(SharelinkTagService.TagsUpdated, object: self)
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
        let result = PersistentManager.sharedInstance.getModel(UserSharelinkTags.self, idValue: userId)
        let req = GetLinkedUserTagsRequest()
        req.userId = userId
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<[SharelinkTag]>) -> Void in
            if let utags = result.returnObject
            {
                let userTags = UserSharelinkTags()
                userTags.userId = userId
                userTags.tags = utags
                userTags.saveModel()
                if let callback = updated
                {
                    callback(userTags.tags)
                }
            }
        }
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