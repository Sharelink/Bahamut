//
//  ShareService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class ShareThingSortObject: ShareLinkObject
{
    override func getObjectUniqueIdName() -> String {
        return "shareId"
    }
    var shareId:String!
    var lastActiveDateString:String!
    var lastActiveDate:NSDate!{
        if let res = DateHelper.stringToDate(self.lastActiveDateString)
        {
            return res
        }
        return NSDate()
    }
}

class ShareThingSortObjectList
{
    private(set) var list:[ShareThingSortObject]!
    init()
    {
        list = PersistentManager.sharedInstance.getAllModelFromCache(ShareThingSortObject)
    }
    
    func sort()
    {
        list.sortInPlace { (a, b) -> Bool in
            a.lastActiveDate.timeIntervalSince1970 > b.lastActiveDate.timeIntervalSince1970
        }
    }
    
    func setShareThings(items:[ShareThing]!)
    {
        if items == nil
        {
            return
        }
        for item in items
        {
            self.setShareThing(item)
        }
        self.sort()
    }
    
    func setShareThing(item:ShareThing)
    {
        for obj in list
        {
            if obj.shareId == item.shareId
            {
                obj.lastActiveDateString = item.lastActiveTime
                obj.saveModel()
                return
            }
        }
        let obj = ShareThingSortObject()
        obj.shareId = item.shareId
        obj.lastActiveDateString = item.lastActiveTime
        list.insert(obj, atIndex: 0)
        obj.saveModel()
    }
    
    func getSortedObjects(startIndex:Int,pageNum:Int) -> [ShareThingSortObject]
    {
        var result = [ShareThingSortObject]()
        let lastIndex = min(list.count,startIndex + pageNum)
        for var i = startIndex; i < lastIndex;i++
        {
            result.append(list[i])
        }
        return result
    }
    
    func getSortedShareId(startIndex:Int,pageNum:Int) -> [String]
    {
        return getSortedObjects(startIndex, pageNum: pageNum).map{transform -> String in
            return transform.shareId
        }
    }
}

class ShareService: ServiceProtocol
{
    @objc static var ServiceName:String{return "share service"}
    @objc func appStartInit()
    {
        
    }
    
    @objc func userLoginInit(userId:String)
    {
        initSortObjectList()
    }
    
    private func initSortObjectList()
    {
        shareThingSortObjectList = ShareThingSortObjectList()
    }
    
    private var shareThingSortObjectList:ShareThingSortObjectList!
    
    func getNewShareThings(updatedCallback:((haveChange:Bool)->Void)! = nil)
    {
        let req = GetShareThingsRequest()
        
        if let firstThing = self.shareThingSortObjectList.list.first
        {
            req.newerThanThisTime = firstThing.lastActiveDate
            req.page = 0
            req.pageCount = 3
        }else
        {
            req.olderThanThisTime = NSDate()
            req.page = 1
            req.pageCount = 3
        }
        
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req) { (result:SLResult<[ShareThing]>) -> Void in
            
            var modified:Bool = true
            
            if result.statusCode == ReturnCode.NotModified
            {
                modified = false
            }else if result.statusCode == ReturnCode.OK
            {
                if let newValues:[ShareThing] = result.returnObject
                {
                    if newValues.count > 0
                    {
                        self.shareThingSortObjectList.setShareThings(newValues)
                        ShareLinkObject.saveObjectOfArray(newValues)
                        modified = true
                    }
                }
            }
            if let update = updatedCallback
            {
                update(haveChange:modified)
            }
        }
        
    }
    
    func getShareThings(startIndex:Int, pageNum:Int = 20) -> [ShareThing]
    {
        return PersistentManager.sharedInstance.getModels(ShareThing.self, idValues: self.shareThingSortObjectList.getSortedShareId(startIndex, pageNum: pageNum))
    }
    
    func getNextPageShareThings(startIndex:Int, pageNum:Int = 20, returnCallback:([ShareThing])->Void)
    {
        let result = PersistentManager.sharedInstance.getModels(ShareThing.self, idValues: self.shareThingSortObjectList.getSortedShareId(startIndex, pageNum: pageNum))
        if result.count > 0
        {
            returnCallback(result)
            return
        }
        if self.shareThingSortObjectList.list.count == 0
        {
            returnCallback([ShareThing]())
            return
        }
        let req = GetShareThingsRequest()
        req.olderThanThisTime = self.shareThingSortObjectList.list.last?.lastActiveDate
        req.page = 1
        req.pageCount = pageNum
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<[ShareThing]>) -> Void in
            if result.statusCode == ReturnCode.NotModified
            {
                returnCallback([ShareThing]())
            }else if result.statusCode == ReturnCode.OK
            {
                if let newValues:[ShareThing] = result.returnObject
                {
                    if newValues.count > 0
                    {
                        self.shareThingSortObjectList.setShareThings(newValues)
                        ShareLinkObject.saveObjectOfArray(newValues)
                        returnCallback(newValues)
                        return
                    }
                }
                returnCallback([ShareThing]())
            }
        }
        
    }
    
    func unVoteShareThing(shareThingModel:ShareThing,updateCallback:(()->Void)! = nil)
    {
        let myUserId = ServiceContainer.getService(UserService).myUserId
        let req = DeleteVoteRequest()
        req.shareId = shareThingModel.shareId
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                for var i:Int = shareThingModel.voteUsers.count - 1; i >= 0; i--
                {
                    if shareThingModel.voteUsers[i] == myUserId
                    {
                        shareThingModel.voteUsers.removeAtIndex(i)
                    }
                }
                shareThingModel.saveModel()
            }
            if let update = updateCallback
            {
                update()
            }
        }
    }
    
    func voteShareThing(shareThingModel:ShareThing,updateCallback:(()->Void)! = nil)
    {
        let myUserId = ServiceContainer.getService(UserService).myUserId
        let req = AddVoteRequest()
        req.shareId = shareThingModel.shareId
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                shareThingModel.voteUsers.append(myUserId)
                shareThingModel.lastActiveTime = DateHelper.toDateTimeString(NSDate())
                shareThingModel.saveModel()
            }
            if let update = updateCallback
            {
                update()
            }
        }
    }
    
    func getShareThings(shareIds:[String],updatedCallback:((haveChange:Bool,newValues:[ShareThing]!)->Void)! = nil) -> [ShareThing]
    {
        let oldValues = [ShareThing]()
        //TODO: read from cache
        
        //Access Network
        let req = GetShareThingsRequest()
        req.page = 1
        req.pageCount = 0
        req.shareIds = shareIds
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<[ShareThing]>) ->Void in
            var modified:Bool = true
            var newValues:[ShareThing]! = nil
            if result.statusCode == ReturnCode.NotModified
            {
                modified = false
            }else if result.statusCode == ReturnCode.OK
            {
                newValues = result.returnObject ?? [ShareThing]()
                ShareLinkObject.saveObjectOfArray(newValues)
            }
            if let update = updatedCallback
            {
                update(haveChange: modified, newValues: newValues)
            }
        }
        return oldValues
    }
    
    func reshare(shareId:String,message:String!)
    {
        
    }
    
    func postNewShare(newShare:ShareThing,tags:[SharelinkTag],callback:(isSuc:Bool)->Void)
    {
        let req = AddNewShareThingRequest()
        req.shareContent = newShare.shareContent
        req.title = newShare.title
        req.tags = tags.map{ $0.getTagString()}.joinWithSeparator("#")
        req.shareType = newShare.shareType
        req.pShareId = newShare.pShareId
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<ShareThing>) -> Void in
            if result.isSuccess
            {
                newShare.lastActiveTime = DateHelper.toDateTimeString(NSDate())
                newShare.shareId = result.returnObject.shareId
                newShare.saveModel()
            }
            callback(isSuc: result.isSuccess)
        }
    }
    
}