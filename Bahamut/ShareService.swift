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
        return DateHelper.stringToDate(self.lastActiveDateString)
    }
}

class ShareThingSortObjectList
{
    private(set) var list:[ShareThingSortObject]!
    init()
    {
        list = PersistentManager.sharedInstance.getAllModel(ShareThingSortObject)
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
    @objc func initService()
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
        }else
        {
            req.olderThanThisTime = NSDate()
            req.page = 1
            req.pageCount = 10
        }
        
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req, callback: { (result, returnStatus) -> Void in
            
            var modified:Bool = true
            
            if returnStatus.returnCode == ReturnCode.NotModified
            {
                modified = false
            }else if returnStatus.returnCode == ReturnCode.OK
            {
                if let newValues:[ShareThing] = (result as! ShareThings).items
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
        })
        
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
        req.pageCount = 10
        ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.NotModified
            {
                returnCallback([ShareThing]())
            }else if returnStatus.returnCode == ReturnCode.OK
            {
                if let newValues:[ShareThing] = (result as! ShareThings).items
                {
                    if newValues.count > 0
                    {
                        self.shareThingSortObjectList.setShareThings(newValues)
                        ShareLinkObject.saveObjectOfArray(newValues)
                        returnCallback(newValues)
                    }
                }

            }
        })
        
    }
    
    func voteShareThing(shareThingModel:ShareThing,updateCallback:(()->Void)! = nil)
    {
        let myUserId = ServiceContainer.getService(UserService).myUserId
        var index = 0
        for id in shareThingModel.voteUserIds
        {
            if id == myUserId
            {
                break
            }
            index++
        }
        var req:ShareLinkSDKRequestBase!
        if index == shareThingModel.voteUserIds.count
        {
            let areq = AddVoteRequest()
            areq.shareId = shareThingModel.shareId
            shareThingModel.voteUserIds.append(myUserId)
            req = areq
        }else{
            let dreq = DeleteVoteRequest()
            dreq.shareId = shareThingModel.shareId
            shareThingModel.voteUserIds.removeAtIndex(index)
            req = dreq
        }
        ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(req, callback: { (result, returnStatus) -> Void in
            if returnStatus.returnCode == ReturnCode.OK
            {
                if index == shareThingModel.voteUserIds.count
                {
                    shareThingModel.voteUserIds.append(myUserId)
                }else{
                    shareThingModel.voteUserIds.removeAtIndex(index)
                }
                shareThingModel.lastActiveTime = DateHelper.dateToString(NSDate())
                shareThingModel.saveModel()
            }
            if let update = updateCallback
            {
                update()
            }
        })
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
        ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(req, callback: { result, returnStatus in
            var modified:Bool = true
            var newValues:[ShareThing]! = nil
            if returnStatus.returnCode == ReturnCode.NotModified
            {
                modified = false
            }else if returnStatus.returnCode == ReturnCode.OK
            {
                newValues = (result as! ShareThings).items ?? nil
                ShareLinkObject.saveObjectOfArray(newValues)
            }
            if let update = updatedCallback
            {
                update(haveChange: modified, newValues: newValues)
            }
        })
        return oldValues
    }
    
    func getReShareThingsOfShareThing(shareThing:ShareThing,updatedCallback:((haveChange:Bool,newValues:[ShareThing]!)->Void)! = nil) -> [ShareThing]
    {
        let oldValues = [ShareThing]()
        //TODO: read from cache
        
        //Access Network
        let req = GetReShareThingsRequest()
        req.page = 0
        req.pageCount = 0
        req.shareId = shareThing.shareId
        ShareLinkSDK.sharedInstance.getShareLinkClient()?.execute(req, callback: { result, returnStatus in
            var modified:Bool = true
            var newValues:[ShareThing]! = nil
            if returnStatus.returnCode == ReturnCode.NotModified
            {
                modified = false
            }else if returnStatus.returnCode == ReturnCode.OK
            {
                newValues = (result as! ShareThings).items ?? nil
                ShareLinkObject.saveObjectOfArray(newValues)
            }
            if let update = updatedCallback
            {
                update(haveChange: modified, newValues: newValues)
            }
        })
        return oldValues
    }
    
    func test()
    {
        //TODO: delete
        var newValues = [ShareThing]()
        for shareId in 1...7
        {
            let shareThing = ShareThing()
            shareThing.shareId = "\(100 + shareId)"
            let sinceDate:NSDate = DateHelper.stringToDate("2015-07-15 00:00:00")
            sinceDate.dateByAddingTimeInterval(Double(arc4random() % (3600 * 24 * 14)))
            shareThing.shareTime = DateHelper.dateToString(sinceDate)
            let lastActiveTime:NSDate = DateHelper.stringToDate("2015-07-15 00:00:00")
            lastActiveTime.dateByAddingTimeInterval(Double(arc4random() % (3600 * 24 * 14)))
            shareThing.lastActiveTime = DateHelper.dateToString(lastActiveTime)
            shareThing.shareType = 1
            shareThing.title = "一个视频告诉你什么叫“困成狗了” ，好可爱哈哈哈哈！😂"
            shareThing.userId = "\(147258 + arc4random()%(147270-147258))"
            shareThing.userNick =  shareThing.userId == "147258" ? "The Different YY" : "nick:\(shareThing.userId)"
            shareThing.headIconImageId = shareThing.userId == "147258" ? "YY" : "defaultHeadIcon"
            shareThing.voteUserIds = ["147258","147259","147260"]
            shareThing.reShareIds = [String]()
            shareThing.reShareUserIds = [String]()
            shareThing.content = ShareContent()
            shareThing.content.content = "02.mov"
            shareThing.content.shareId = shareThing.shareId
            shareThing.content.contentId = shareThing.shareId
            newValues.append(shareThing)
        }
        self.shareThingSortObjectList.setShareThings(newValues)
        ShareLinkObject.saveObjectOfArray(newValues)
    }
}