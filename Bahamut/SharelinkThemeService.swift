//
//  UserSharelinkThemeService.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: sortable
class SharelinkThemeSortableObject: Sortable
{
    override func getObjectUniqueIdValue() -> String {
        return "themeId"
    }
    
    var themeId:String!
    
    func getTheme() -> SharelinkTheme
    {
        return PersistentManager.sharedInstance.getModel(SharelinkTheme.self, idValue: themeId)!
    }

    override func isOrderedBefore(b: Sortable) -> Bool {
        let intervalA = self.compareValue as? NSNumber ?? NSDate().timeIntervalSince1970
        let intervalB = b.compareValue as? NSNumber ?? NSDate().timeIntervalSince1970
        return intervalA.doubleValue > intervalB.doubleValue
    }
}

extension SharelinkTheme
{
    func getSortableObject() -> SharelinkThemeSortableObject
    {
        if let obj = PersistentManager.sharedInstance.getModel(SharelinkThemeSortableObject.self, idValue: self.tagId)
        {
            return obj
        }
        let obj = SharelinkThemeSortableObject()
        obj.themeId = self.tagId
        obj.compareValue = self.time == nil ? NSNumber(double: 0) : NSNumber(double: self.time.dateTimeOfAccurateString.timeIntervalSince1970)
        return obj
    }
}

//MARK: theme name for show
extension SharelinkTheme
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

//MARK: SharelinkThemeService

public class SharelinkThemeService : NSNotificationCenter, ServiceProtocol
{
    static let ThemesUpdated:String = "ThemesUpdated"
    @objc static var ServiceName:String{return "SharelinkThemeService"}
    
    @objc func userLoginInit(userId: String) {
        self.refreshMyAllSharelinkThemes()
        self.setServiceReady()
    }
    
    func userLogout(userId: String) {
    }
    
    //MARK: My Tag
    func getMyAllThemes() ->[SharelinkTheme]
    {
        return PersistentManager.sharedInstance.getAllModelFromCache(SharelinkTheme)
    }
    
    func getAllCustomThemes() -> [SharelinkTheme]
    {
        let alltags = getMyAllThemes()
        return alltags.filter{ $0.domain == SharelinkThemeConstant.TAG_DOMAIN_CUSTOM}
    }
    
    func getAllSystemThemes() -> [SharelinkTheme]
    {
        let alltags = getMyAllThemes()
        return alltags.filter{ $0.domain == SharelinkThemeConstant.TAG_DOMAIN_SYSTEM}
    }
    
    //refresh all the tag entities
    func refreshMyAllSharelinkThemes()
    {
        let req = GetMyAllTagsRequest()
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req){ (result:SLResult<[SharelinkTheme]>) -> Void in
            if let tags = result.returnObject
            {
                for tag in tags
                {
                    if tag.isSystemTag()
                    {
                        tag.tagName = NSLocalizedString(tag.tagName, comment: "") ?? tag.tagName
                    }
                }
                SharelinkTheme.saveObjectOfArray(tags)
                PersistentManager.sharedInstance.refreshCache(SharelinkTheme)
                self.postNotificationName(SharelinkThemeService.ThemesUpdated, object: self)
            }
        }
    }
    
    func isThemeExists(themeData:String) -> Bool
    {
        return self.getAllCustomThemes().contains{$0.data == themeData}
    }
    
    func addSharelinkTheme(theme:SharelinkTheme,sucCallback:((isSuc:Bool)->Void)! = nil)
    {
        let req = AddNewTagRequest()
        req.tagColor = theme.tagColor
        req.tagName = theme.tagName
        req.isFocus = theme.isFocus
        req.data = theme.data
        req.isShowToLinkers = theme.showToLinkers
        req.type = theme.type
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<SharelinkTheme>) -> Void in
            var suc = false
            if let newTheme = result.returnObject
            {
                newTheme.saveModel()
                PersistentManager.sharedInstance.refreshCache(SharelinkTheme)
                suc = true
                self.postNotificationName(SharelinkThemeService.ThemesUpdated, object: self)
            }
            if let callback = sucCallback
            {
                callback(isSuc: suc)
            }
        })
    }
    
    func removeMyThemes(themes:[SharelinkTheme],sucCallback:(()->Void)! = nil)
    {
        if themes.count == 0
        {
            return
        }
        let req = RemoveTagsRequest()
        req.tagIds = themes.map{$0.tagId}
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<BahamutObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                PersistentManager.sharedInstance.removeModels(themes)
                self.postNotificationName(SharelinkThemeService.ThemesUpdated, object: self)
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
    
    func updateTheme(theme:SharelinkTheme,sucCallback:(()->Void)! = nil)
    {
        let req = UpdateTagRequest()
        req.tagId = theme.tagId
        req.tagName = theme.tagName
        req.tagColor = theme.tagColor
        req.isFocus = theme.isFocus
        req.isShowToLinkers = theme.showToLinkers
        req.type = theme.type
        req.data = theme.data
        let client = SharelinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req, callback: { (result:SLResult<BahamutObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                theme.saveModel()
                PersistentManager.sharedInstance.refreshCache(SharelinkTheme)
                self.postNotificationName(SharelinkThemeService.ThemesUpdated, object: self)
                if let callback = sucCallback
                {
                    callback()
                }
            }
        })
    }
    
    //MARK: Linked User Tag
    
    func getUserTheme(userId:String,updated:(([SharelinkTheme])->Void)!) -> [SharelinkTheme]
    {
        let result = PersistentManager.sharedInstance.getModel(SharelinkerThemes.self, idValue: userId)
        let req = GetLinkedUserTagsRequest()
        req.userId = userId
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<[SharelinkTheme]>) -> Void in
            if let uthemes = result.returnObject
            {
                let userThemes = SharelinkerThemes()
                userThemes.userId = userId
                userThemes.tags = uthemes
                userThemes.saveModel()
                if let callback = updated
                {
                    callback(userThemes.tags)
                }
            }
        }
        return result?.tags ?? [SharelinkTheme]()
    }
    
    func getUserIdsHaveThisThemeOfId(tagId:String) -> [String]
    {
        if let tag = PersistentManager.sharedInstance.getModel(SharelinkTheme.self, idValue: tagId)
        {
            return getUserIdsHaveThisThemeOfThemeName(tag.tagName!)
        }
        return [String]()
    }
    
    func getUserIdsHaveThisThemeOfThemeName(tagName:String) -> [String]
    {
        let usertags = PersistentManager.sharedInstance.getAllModelFromCache(SharelinkerThemes)
        let userIds = usertags.filter{$0.tags.contains{$0.tagName == tagName}}.map{$0.userId!}
        return userIds
    }
    

}