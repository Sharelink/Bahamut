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
    override func isOrderedBefore(b: Sortable) -> Bool {
        let intervalA = self.compareValue as? NSNumber ?? NSDate().timeIntervalSince1970
        let intervalB = b.compareValue as? NSNumber ?? NSDate().timeIntervalSince1970
        return intervalA.doubleValue > intervalB.doubleValue
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
        obj.compareValue = NSNumber(double: self.shareTimeOfDate.timeIntervalSince1970)
        return obj
    }
}

extension ShareUpdatedMessage
{
    func isInvalidData() -> Bool
    {
        return shareId == nil || time == nil
    }
}

//MARK: ShareService
let shareUpdatedNotifyRoute:ChicagoRoute = {
    let route = ChicagoRoute()
    route.ExtName = "NotificationCenter"
    route.CmdName = "UsrNewSTMsg"
    return route
}()

let NewShareMessages = "NewShareMessages"
let UpdatedShares = "UpdatedShares"
let NewSharePostedShareId = "NewSharePostedShareId"

class ShareService: NSNotificationCenter,ServiceProtocol
{
    static let newSharePosted = "newSharePosted"
    static let newSharePostFailed = "newSharePostFailed"
    static let startPostingShare = "startPostingShare"
    static let newShareMessagesUpdated = "newShareMessagesUpdated"
    static let shareUpdated = "shareUpdated"
    @objc static var ServiceName:String{return "Share Service"}
    
    @objc func userLoginInit(userId:String)
    {
        resetSortObjectList()
        ChicagoClient.sharedInstance.addChicagoObserver(shareUpdatedNotifyRoute, observer: self, selector: "newShareMessagesNotify:")
        self.setServiceReady()
        self.getNewShareMessageFromServer()
    }
    
    func userLogout(userId: String) {
        newShareTime = nil
        oldShareTime = nil
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    var allShareLoaded:Bool = false
    private(set) var sendingShareId = [String:String]()
    
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
    
    let lock:NSRecursiveLock = NSRecursiveLock()
    func setSortableObjects(objects:[ShareThingSortableObject])
    {
        self.lock.lock()
        self.shareThingSortObjectList.setSortableItems(objects)
        self.lock.unlock()
    }
    
    //MARK: chicago client
    func newShareMessagesNotify(a:NSNotification)
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
    
    func getPreviousShare(callback:((previousShares:[ShareThing]!)->Void)! = nil) -> Bool
    {
        if oldShareTime == nil
        {
            return false
        }
        let req = GetShareThingsRequest()
        req.endTime = oldShareTime
        req.page = 0
        req.pageCount = 7
        return requestShare(req,callback: callback)
    }
    
    private func requestShare(req:GetShareThingsRequest,callback:((reqShares:[ShareThing]!)->Void)!) -> Bool
    {
        allShareLoaded = false
        let client = BahamutRFKit.sharedInstance.getBahamutClient() as! BahamutRFClient
        return client.execute(req) { (result:SLResult<[ShareThing]>) -> Void in
            
            var shares:[ShareThing]! = nil
            if result.statusCode == ReturnCode.OK
            {
                if let newValues:[ShareThing] = result.returnObject
                {
                    if newValues.count > 0
                    {
                        let sortables = newValues.map{$0.getSortableObject()}
                        ShareThing.saveObjectOfArray(newValues)
                        self.updateNewShareAndOldShareTime(newValues)
                        self.setSortableObjects(sortables)
                        shares = newValues
                    }else
                    {
                        self.allShareLoaded = true
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
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req) { (result:SLResult<[ShareThing]>) ->Void in
            var shares:[ShareThing]! = nil
            if result.statusCode == ReturnCode.OK && result.returnObject != nil && result.returnObject.count > 0
            {
                shares = result.returnObject!
                ShareThing.saveObjectOfArray(shares)
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
        return PersistentManager.sharedInstance.getModels(ShareThing.self, idValues: self.shareThingSortObjectList.getSortedObjects(startIndex, pageNum: pageNum).map{ $0.shareId })
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
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req){ (result:SLResult<[ShareUpdatedMessage]>) ->Void in
            if var msgs = result.returnObject
            {
                msgs = msgs.filter{!$0.isInvalidData()} //AlamofireJsonToObject Issue:responseArray will invoke all completeHandler
                if msgs.count == 0
                {
                    return
                }
                self.postNotificationName(ShareService.newShareMessagesUpdated, object: self, userInfo: [NewShareMessages:msgs])
                self.getSharesWithShareIds(msgs.map{$0.shareId }){ (reqShares) -> Void in
                    if let shares = reqShares
                    {
                        var msgMap = [String:ShareUpdatedMessage]()
                        for m in msgs{
                            msgMap[m.shareId] = m
                        }
                        func shareToSortable(share:ShareThing) -> ShareThingSortableObject
                        {
                            let obj = share.getSortableObject()
                            let timeInterval = DateHelper.stringToDateTime(msgMap[share.shareId]?.time).timeIntervalSince1970
                            obj.compareValue = NSNumber(double: timeInterval)
                            return obj
                        }
                        let sortables = shares.map{shareToSortable($0)}
                        self.setSortableObjects(sortables)
                        self.postNotificationName(ShareService.shareUpdated, object: self, userInfo: [UpdatedShares:shares])
                        self.clearShareMessageBox()
                    }
                }
            }
        }
    }
    
    func clearShareMessageBox()
    {
        let req = ClearShareUpdatedMessageRequest()
        
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req){ (result:SLResult<[ShareUpdatedMessage]>) ->Void in
        }
    }
    
    //MARK: Create Share
    func reshare(shareId:String,message:String!,tags:[SharelinkTheme],callback:(suc:Bool,shareId:String!)->Void)
    {
        let req = ReShareRequest()
        req.pShareId = shareId
        req.message = message
        req.tags = tags
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<ShareThing>) -> Void in
            if result.isSuccess
            {
                let newShare = result.returnObject
                newShare.saveModel()
                let sortableObject = newShare.getSortableObject()
                self.setSortableObjects([sortableObject])
                callback(suc: true,shareId: newShare.shareId)
            }else
            {
                callback(suc: false,shareId: nil)
            }
        }
    }
    
    func postNewShare(newShare:ShareThing,tags:[SharelinkTheme],callback:(shareId:String!)->Void)
    {
        let req = AddNewShareThingRequest()
        req.shareContent = newShare.shareContent
        req.message = newShare.message
        req.tags = tags
        req.shareType = newShare.shareType
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        self.postNotificationName(ShareService.startPostingShare, object: nil)
        client.execute(req) { (result:SLResult<ShareThing>) -> Void in
            if result.isSuccess
            {
                newShare.shareId = result.returnObject.shareId
                newShare.saveModel()
                let sortableObject = newShare.getSortableObject()
                self.setSortableObjects([sortableObject])
                self.sendingShareId[newShare.shareId] = "true"
            }else
            {
                self.postNotificationName(ShareService.newSharePostFailed, object: self, userInfo: nil)
            }
            callback(shareId: newShare.shareId)
        }
    }
    
    func postNewShareFinish(shareId:String,isCompleted:Bool,callback:(isSuc:Bool)->Void)
    {
        let req = FinishNewShareThingRequest()
        req.shareId = shareId
        req.taskSuccess = isCompleted
        let client = BahamutRFKit.sharedInstance.getBahamutClient()
        client.execute(req) { (result:SLResult<ShareThing>) -> Void in
            if let _ = result.returnObject
            {
                self.sendingShareId.removeValueForKey(shareId)
                self.postNotificationName(ShareService.newSharePosted, object: self, userInfo: [NewSharePostedShareId:shareId])
                callback(isSuc: true)
            }else
            {
                self.postNotificationName(ShareService.newSharePostFailed, object: self, userInfo: [NewSharePostedShareId:shareId])
                callback(isSuc: false)
            }
        }
    }
    
    //MARK: Vote
    
    func unVoteShareThing(shareThingModel:ShareThing,updateCallback:(()->Void)! = nil)
    {
        let myUserId = ServiceContainer.getService(UserService).myUserId
        let req = DeleteVoteRequest()
        req.shareId = shareThingModel.shareId
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req){ (result:SLResult<BahamutObject>) -> Void in
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
        BahamutRFKit.sharedInstance.getBahamutClient().execute(req){ (result:SLResult<BahamutObject>) -> Void in
            if result.statusCode == ReturnCode.OK
            {
                if share.voteUsers == nil{
                    share.voteUsers = [myUserId]
                }else
                {
                    share.voteUsers.append(myUserId)
                }
                share.saveModel()
                let sortableObj = share.getSortableObject()
                sortableObj.compareValue = NSNumber(double: NSDate().timeIntervalSince1970)
                self.setSortableObjects([sortableObj])
            }
            if let update = updateCallback
            {
                update()
            }
        }
    }
}