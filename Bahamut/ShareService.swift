//
//  ShareService.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/29.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

//MARK: sortable share thing

class ShareThingSortableObject: Sortable
{
    override func getObjectUniqueIdName() -> String {
        return "shareId"
    }
    var shareId:String!
    var lastActiveDate:NSDate{
        return (self.compareValue as? NSDate) ?? NSDate()
    }
    override func isOrderedBefore(b: Sortable) -> Bool {
        let lastActiveDateA = self.lastActiveDate
        let lastActiveDateB = (b as! ShareThingSortableObject).lastActiveDate
        return lastActiveDateA.timeIntervalSince1970 > lastActiveDateB.timeIntervalSince1970
    }
}

extension ShareThing
{
    func getSortableObject() -> ShareThingSortableObject
    {
        let obj = ShareThingSortableObject()
        obj.shareId = self.shareId
        obj.compareValue = self.lastActiveTimeOfDate
        return obj
    }
}

//MARK: ShareService

class ShareService: NSNotificationCenter,ServiceProtocol
{
    static let shareUpdated = "newShareUpdated"
    @objc static var ServiceName:String{return "share service"}
    @objc func appStartInit()
    {
        
    }
    
    @objc func userLoginInit(userId:String)
    {
        initSortObjectList()
        
        let shareUpdatedNotifyRoute = ChicagoRoute()
        shareUpdatedNotifyRoute.ExtName = "NotificationCenter"
        shareUpdatedNotifyRoute.CmdName = "UsrNewSTMsg"
        ChicagoClient.sharedInstance.addChicagoObserver(shareUpdatedNotifyRoute, observer: self, selector: "shareUpdatedMsgReceived:")
    }
    
    func userLogout(userId: String) {
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    private func initSortObjectList()
    {
        let initList = PersistentManager.sharedInstance.getAllModelFromCache(ShareThingSortableObject.self)
        shareThingSortObjectList = SortableObjectList<ShareThingSortableObject>(initList: initList)
    }
    
    private var shareThingSortObjectList:SortableObjectList<ShareThingSortableObject>!
    
    //MARK: Chicago Notify
    func shareUpdatedMsgReceived(a:NSNotification)
    {
        self.getNewShareMessageFromServer()
    }
    
    //MARK: Get Shares
    func getNewShareThings(updatedCallback:((haveChange:Bool)->Void)! = nil)
    {
        let req = GetShareThingsRequest()
        
        if let firstThing = self.shareThingSortObjectList.list.first
        {
            req.beginTime = firstThing.lastActiveDate
            req.endTime = NSDate()
            req.page = -1
        }else
        {
            req.endTime = NSDate()
            req.page = 0
            req.pageCount = 20
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
                        let sortables = newValues.map{$0.getSortableObject()}
                        self.shareThingSortObjectList.setSortableItems(sortables)
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
        req.endTime = self.shareThingSortObjectList.list.last?.lastActiveDate
        req.page = 0
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
                        let sortables = newValues.map{$0.getSortableObject()}
                        self.shareThingSortObjectList.setSortableItems(sortables)
                        ShareLinkObject.saveObjectOfArray(newValues)
                        returnCallback(newValues)
                        return
                    }
                }
                returnCallback([ShareThing]())
            }
        }
        
    }
    
    func getShareThing(shareId:String) -> ShareThing!
    {
        if let share = PersistentManager.sharedInstance.getModel(ShareThing.self, idValue: shareId)
        {
            shareThingSortObjectList.setSortableItem(share.getSortableObject())
            return share
        }
        return nil
    }
    
    func sortShareThingList()
    {
        shareThingSortObjectList.sort()
    }
    
    func getShareThings(shareIds:[String],updatedCallback:((haveChange:Bool,newValues:[ShareThing]!)->Void)! = nil) -> [ShareThing]
    {
        //read from cache
        let oldValues = PersistentManager.sharedInstance.getModels(ShareThing.self, idValues: shareIds)
        
        //Access Network
        let req = GetShareOfShareIdsRequest()
        req.shareIds = shareIds
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<[ShareThing]>) ->Void in
            var modified:Bool = false
            var newValues:[ShareThing]! = nil
            if result.statusCode == ReturnCode.OK
            {
                newValues = result.returnObject ?? [ShareThing]()
                let sortables = newValues.map{$0.getSortableObject()}
                self.shareThingSortObjectList.setSortableItems(sortables)
                ShareLinkObject.saveObjectOfArray(newValues)
                modified = newValues.count > 0
            }
            if let update = updatedCallback
            {
                update(haveChange: modified, newValues: newValues)
            }
        }
        return oldValues
    }
    
    //MARK: Share Messages
    func getNewShareMessageFromServer()
    {
        let req = GetShareUpdatedMessageRequest()
        
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<[ShareUpdatedMessage]>) ->Void in
            if let msgs = result.returnObject
            {
                self.getShareThings(msgs.map{$0.shareId }, updatedCallback: { (haveChange, newValues) -> Void in
                    self.postNotificationName(ShareService.shareUpdated, object: self)
                    self.clearShareMessageBox()
                })
            }
        }
    }
    
    func clearShareMessageBox()
    {
        let req = ClearShareUpdatedMessageRequest()
        
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<[ShareUpdatedMessage]>) ->Void in
        }
    }
    
    //MARK: Create Share
    func reshare(shareId:String,message:String!)
    {
        
    }
    
    func postNewShare(newShare:ShareThing,tags:[SharelinkTag],callback:(shareId:String!)->Void)
    {
        let req = AddNewShareThingRequest()
        req.shareContent = newShare.shareContent
        req.title = newShare.title
        req.tags = tags.map{ $0.data ?? $0.tagName}.joinWithSeparator("#")
        req.shareType = newShare.shareType
        req.pShareId = newShare.pShareId
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<ShareThing>) -> Void in
            if result.isSuccess
            {
                newShare.lastActiveTime = DateHelper.toDateTimeString(NSDate())
                newShare.shareId = result.returnObject.shareId
                self.shareThingSortObjectList.setSortableItem(newShare.getSortableObject())
                newShare.saveModel()
            }
            callback(shareId: newShare.shareId)
        }
    }
    
    func postNewShareFinish(shareId:String,isCompleted:Bool)
    {
        let req = FinishNewShareThingRequest()
        req.shareId = shareId
        req.taskSuccess = isCompleted
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient()
        client.execute(req) { (result:SLResult<ShareThing>) -> Void in
        }
    }
    
    //MARK: Vote
    
    func unVoteShareThing(shareThingModel:ShareThing,updateCallback:(()->Void)! = nil)
    {
        let myUserId = ServiceContainer.getService(UserService).myUserId
        let req = DeleteVoteRequest()
        req.shareId = shareThingModel.shareId
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                shareThingModel.voteUsers.removeElement{$0 == myUserId}
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

    
}