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
        if let obj = PersistentManager.sharedInstance.getModel(ShareThingSortableObject.self, idValue: self.shareId)
        {
            return obj
        }
        let obj = ShareThingSortableObject()
        obj.shareId = self.shareId
        obj.compareValue = self.shareTimeOfDate
        obj.saveModel()
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
        resetSortObjectList()
        
        let shareUpdatedNotifyRoute = ChicagoRoute()
        shareUpdatedNotifyRoute.ExtName = "NotificationCenter"
        shareUpdatedNotifyRoute.CmdName = "UsrNewSTMsg"
        ChicagoClient.sharedInstance.addChicagoObserver(shareUpdatedNotifyRoute, observer: self, selector: "shareUpdatedMsgReceived:")
    }
    
    func userLogout(userId: String) {
        newShareTime = nil
        oldShareTime = nil
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    private var _newShareTime:NSDate!
    private var newShareTime:NSDate!{
        get{
            if _newShareTime == nil
            {
                _newShareTime = NSUserDefaults.standardUserDefaults().valueForKey("newShareTime") as? NSDate
            }
            return _newShareTime
        }
        set{
            _newShareTime = newValue
            NSUserDefaults.standardUserDefaults().setValue(_newShareTime, forKey: "newShareTime")
        }
    }
    
    private var _oldShareTime:NSDate!
    private var oldShareTime:NSDate!{
        get{
            if _oldShareTime == nil
            {
                _oldShareTime = NSUserDefaults.standardUserDefaults().valueForKey("oldShareTime") as? NSDate
            }
            return _oldShareTime
        }
        set{
            _oldShareTime = newValue
            NSUserDefaults.standardUserDefaults().setValue(_oldShareTime, forKey: "oldShareTime")
        }
    }
    
    private var shareThingSortObjectList:SortableObjectList<ShareThingSortableObject>!
    
    private func resetSortObjectList()
    {
        PersistentManager.sharedInstance.refreshCache(ShareThingSortableObject.self)
        let initList = PersistentManager.sharedInstance.getAllModelFromCache(ShareThingSortableObject.self)
        shareThingSortObjectList = SortableObjectList<ShareThingSortableObject>(initList: initList)
    }
    
    func setSortableObjects(objects:[ShareThingSortableObject])
    {
        self.shareThingSortObjectList.setSortableItems(objects)
    }
    
    //MARK: Chicago Notify
    func shareUpdatedMsgReceived(a:NSNotification)
    {
        self.getNewShareMessageFromServer()
    }
    
    //MARK: Get Shares From Server
    func getNewShareThings(callback:((newShares:[ShareThing]!)->Void)! = nil)
    {
        let req = GetShareThingsRequest()
        
        if let newestShareTime = self.newShareTime
        {
            req.beginTime = newestShareTime
            req.endTime = NSDate()
            req.page = -1
        }else
        {
            req.endTime = NSDate()
            req.page = 0
            req.pageCount = 7
        }
        requestShare(req,callback:callback)
    }
    
    func getPreviousShare(callback:((previousShares:[ShareThing]!)->Void)! = nil)
    {
        if oldShareTime == nil
        {
            return
        }
        let req = GetShareThingsRequest()
        req.endTime = oldShareTime
        req.page = 0
        req.pageCount = 7
        requestShare(req,callback: callback)
    }
    
    private func requestShare(req:GetShareThingsRequest,callback:((reqShares:[ShareThing]!)->Void)!)
    {
        let client = ShareLinkSDK.sharedInstance.getShareLinkClient() as! ShareLinkSDKClient
        client.execute(req) { (result:SLResult<[ShareThing]>) -> Void in
            
            var shares:[ShareThing]! = nil
            if result.statusCode == ReturnCode.OK
            {
                if let newValues:[ShareThing] = result.returnObject
                {
                    if newValues.count > 0
                    {
                        let sortables = newValues.map{$0.getSortableObject()}
                        ShareLinkObject.saveObjectOfArray(sortables)
                        ShareLinkObject.saveObjectOfArray(newValues)
                        self.updateNewShareAndOldShareTime(newValues)
                        self.setSortableObjects(sortables)
                        shares = newValues
                    }
                }
            }
            if let handler = callback
            {
                handler(reqShares: shares)
            }
        }
    }
    
    private func updateNewShareAndOldShareTime(requestShares:[ShareThing])
    {
        var oldestTime = NSDate()
        var newestTime = DateHelper.stringToDate("2015-07-07")
        for s in requestShares
        {
            let shareTime = s.shareTimeOfDate
            if shareTime.timeIntervalSince1970 > newestTime.timeIntervalSince1970
            {
                newestTime = shareTime
            }
            
            if shareTime.timeIntervalSince1970 < oldestTime.timeIntervalSince1970
            {
                oldestTime = shareTime
            }
        }
        
        if newShareTime == nil || newShareTime.timeIntervalSince1970 < newestTime.timeIntervalSince1970
        {
            newShareTime = newestTime
        }
        
        if oldShareTime == nil || oldShareTime.timeIntervalSince1970 > oldestTime.timeIntervalSince1970
        {
            oldShareTime = oldestTime
        }
    }
    
    func getSharesWithShareIds(shareIds:[String],callback:((updatedShares:[ShareThing]!)->Void)! = nil) -> [ShareThing]
    {
        //read from cache
        let oldValues = PersistentManager.sharedInstance.getModels(ShareThing.self, idValues: shareIds)
        
        //Access Network
        let req = GetShareOfShareIdsRequest()
        req.shareIds = shareIds
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<[ShareThing]>) ->Void in
            var shares:[ShareThing]! = nil
            if result.statusCode == ReturnCode.OK && result.returnObject != nil && result.returnObject.count > 0
            {
                shares = result.returnObject!
                ShareLinkObject.saveObjectOfArray(shares)
                let sortables = shares.map{$0.getSortableObject()}
                self.setSortableObjects(sortables)
            }
            if let update = callback
            {
                update(updatedShares: shares)
            }
        }
        return oldValues
    }
    
    //Get shares from local
    func getShareThings(startIndex:Int, pageNum:Int) -> [ShareThing]
    {
        return PersistentManager.sharedInstance.getModels(ShareThing.self, idValues: self.shareThingSortObjectList.getSortedShareId(startIndex, pageNum: pageNum))
    }
    
    func getShareThing(shareId:String) -> ShareThing!
    {
        if let share = PersistentManager.sharedInstance.getModel(ShareThing.self, idValue: shareId)
        {
            return share
        }
        return nil
    }
    
    //MARK: Share Messages
    func getNewShareMessageFromServer()
    {
        let req = GetShareUpdatedMessageRequest()
        
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<[ShareUpdatedMessage]>) ->Void in
            if let msgs = result.returnObject
            {
                if msgs.count == 0
                {
                    return
                }
                self.getSharesWithShareIds(msgs.map{$0.shareId }){ (reqShares) -> Void in
                    if let shares = reqShares
                    {
                        var msgMap = [String:ShareUpdatedMessage]()
                        for m in msgs{
                            msgMap[m.shareId] = m
                        }
                        let _ = shares.map{
                            let obj = $0.getSortableObject()
                            obj.compareValue = DateHelper.stringToDateTime(msgMap[$0.shareId]?.time)
                            obj.saveModel()
                        }
                        self.postNotificationName(ShareService.shareUpdated, object: self)
                        self.clearShareMessageBox()
                    }
                }
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
                newShare.shareId = result.returnObject.shareId
                newShare.saveModel()
                newShare.getSortableObject()
                self.postNotificationName(ShareService.shareUpdated, object: self)
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
    
    func voteShareThing(share:ShareThing,updateCallback:(()->Void)! = nil)
    {
        let myUserId = ServiceContainer.getService(UserService).myUserId
        let req = AddVoteRequest()
        req.shareId = share.shareId
        ShareLinkSDK.sharedInstance.getShareLinkClient().execute(req){ (result:SLResult<ShareLinkObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                share.voteUsers.append(myUserId)
                share.saveModel()
                let sortableObj = share.getSortableObject()
                sortableObj.compareValue = NSDate()
                sortableObj.saveModel()
            }
            if let update = updateCallback
            {
                update()
            }
        }
    }

    
}