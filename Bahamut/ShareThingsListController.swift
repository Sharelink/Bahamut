//
//  ShareThingsListController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import MJRefresh

//MARK: ShareThingsListController
class ShareThingsListController: UITableViewController
{
    
    private(set) var userService:UserService!
    private(set) var fileService:FileService!
    private(set) var messageService:MessageService!
    var shareService = ServiceContainer.getService(ShareService)
    var shareThings:[ShareThing] = [ShareThing]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userService = ServiceContainer.getService(UserService)
        fileService = ServiceContainer.getService(FileService)
        messageService = ServiceContainer.getService(MessageService)
        ChicagoClient.sharedInstance.addObserver(self, selector: "chicagoClientStateChanged:", name: ChicagoClientStateChanged, object: nil)
        initTableView()
        initRefresh()
        changeNavigationBarColor()
        self.shareService = ServiceContainer.getService(ShareService)
        messageService.addObserver(self, selector: "newMessageReceived:", name: MessageService.messageServiceNewMessageReceived, object: nil)
        shareService.addObserver(self, selector: "serverShareUpdated:", name: ShareService.shareUpdated, object: nil)
        refresh()
    }
    
    deinit{
        ServiceContainer.getService(MessageService).removeObserver(self)
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    
    private func initTableView()
    {
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        tableView.tableFooterView = uiview
    }
    
    private func initRefresh()
    {
        tableView.header = MJRefreshNormalHeader(){self.refreshFromServer()}
        tableView.footer = MJRefreshAutoNormalFooter(){self.loadNextPage()}
        tableView.footer.automaticallyHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarItem.badgeValue = nil
        refreshFromServer()
    }
    
    
    var isNetworkError:Bool = false{
        didSet{
            if tableView != nil
            {
                tableView.reloadData()
            }
        }
    }
    
    //MARK: chicago client
    
    func chicagoClientStateChanged(aNotification:NSNotification)
    {
        tableView.reloadData()
    }
    
    func reconnectChicagoClient(_:UIGestureRecognizer)
    {
        ChicagoClient.sharedInstance.reConnect()
    }
    
    //MARK: message
    func newMessageReceived(aNotification:NSNotification)
    {
        if let messages = aNotification.userInfo?[MessageServiceNewMessageEntities] as? [MessageEntity]
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshShareLastActiveTime(messages)
            })
        }
    }
    
    private func refreshShareLastActiveTime(messages:[MessageEntity])
    {
        self.tabBarItem.badgeValue = "\(messages.count)"
        var notReadyShare = [String]()
        var notReadyMsgDate = [String:NSDate]()
        var readySortables = [String:ShareThingSortableObject]()
        for msg in messages
        {
            if let share = shareService.getShareThing(msg.shareId)
            {
                let shareSortable = share.getSortableObject()
                let oldTime = shareSortable.compareValue as! NSNumber
                let newTime = msg.time
                if oldTime.doubleValue < newTime.timeIntervalSince1970
                {
                    shareSortable.compareValue = NSNumber(double: newTime.timeIntervalSince1970)
                }
                readySortables.updateValue(shareSortable, forKey: share.shareId)
            }else
            {
                if let oldTime = notReadyMsgDate[msg.shareId]
                {
                    if oldTime.timeIntervalSince1970 < msg.time.timeIntervalSince1970
                    {
                        notReadyMsgDate.updateValue(msg.time, forKey: msg.shareId)
                    }
                }else
                {
                    notReadyShare.append(msg.shareId)
                    notReadyMsgDate.updateValue(msg.time, forKey: msg.shareId)
                }
                
            }
        }
        self.shareService.setSortableObjects(readySortables.values.map{$0})
        if notReadyShare.count > 0
        {
            shareService.getSharesWithShareIds(notReadyShare, callback: { (updatedShares) -> Void in
                if let shares = updatedShares
                {
                    func shareToSortable(share:ShareThing) -> ShareThingSortableObject
                    {
                        let shareSortable = share.getSortableObject()
                        let timeInterval = notReadyMsgDate[share.shareId]?.timeIntervalSince1970
                        shareSortable.compareValue = NSNumber(double: timeInterval!)
                        return shareSortable
                    }
                    let sortables = shares.map{shareToSortable($0)}
                    self.shareService.setSortableObjects(sortables)
                }
            })
        }
        
    }
    
    //Data refresh
    
    func serverShareUpdated(aNotification:NSNotification)
    {
        refresh()
    }

    let refreshLock = NSRecursiveLock()
    func refresh()
    {
        
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.refreshLock.lock()
            self.shareThings.removeAll(keepCapacity: true)
            let newValues = self.shareService.getShareThings(0,pageNum: 7)
            self.shareThings.insertContentsOf(newValues, at: 0)
            self.tableView.reloadData()
            self.refreshLock.unlock()
            self.tableView.scrollToNearestSelectedRowAtScrollPosition(.Top, animated: true)
        }
    }
    
    func refreshFromServer()
    {
        self.shareService.getNewShareThings { (newShares) -> Void in
            self.tableView.header.endRefreshing()
            if newShares == nil{
                return
            }
            self.refresh()
        }
    }
    
    
    func loadNextPage()
    {
        if shareThings.count == 0
        {
            return
        }
        let startIndex = shareThings.count
        let shares = self.shareService.getShareThings(startIndex, pageNum: 10)
        if shares.count > 0
        {
            self.refreshLock.lock()
            self.shareThings.insertContentsOf(shares, at: startIndex)
            self.tableView.footer.endRefreshing()
            self.tableView.reloadData()
            self.refreshLock.unlock()
        }else
        {
            self.shareService.getPreviousShare({ (previousShares) -> Void in
                self.tableView.footer.endRefreshing()
                if previousShares != nil && previousShares.count > 0
                {
                    self.refreshLock.lock()
                    self.shareThings.insertContentsOf(previousShares, at: startIndex)
                    self.tableView.reloadData()
                    self.refreshLock.unlock()
                }
            })
        }
    }
    
    //MARK: actions
    
    @IBAction func tag(sender: AnyObject)
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        view.makeToastActivity()
        tagService.refreshMyAllSharelinkTags { () -> Void in
            self.view.hideToastActivity()
            let allTagModels = tagService.getMyAllTags()
            tagService.showTagExplorerController(self.navigationController!, tags: tagService.getUserTagsResourceItemModels(allTagModels))
        }
    }
    
    @IBAction func userSetting(sender:AnyObject)
    {
        userService.showMyDetailView(self.navigationController!)
    }
    
    //MARK: tableView delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return shareThings.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if ChicagoClient.sharedInstance.clientState != ChicagoClientState.Validated
        {
            return 35
        }
        return 0
    }
    
    var stateHeaderView:UIClientStateHeader!{
        didSet{
            stateHeaderView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "reconnectChicagoClient:"))
        }
    }


    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cstate = ChicagoClient.sharedInstance.clientState
        if cstate != ChicagoClientState.Validated
        {
            if stateHeaderView == nil
            {
                stateHeaderView = NSBundle.mainBundle().loadNibNamed("UIViews", owner: nil, options: nil).filter{$0 is UIClientStateHeader}.first as! UIClientStateHeader
            }
            if cstate == ChicagoClientState.Disconnected
            {
                stateHeaderView.setConnectError()
            }else
            {
                stateHeaderView.startConnect()
            }
            return stateHeaderView
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let shareThing = shareThings[indexPath.row] as ShareThing
        if shareThing.shareType == ShareType.messageType.rawValue
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIShareMessage.RollMessageCellIdentifier, forIndexPath: indexPath) as! UIShareMessage
            cell.rootController = self
            cell.shareThingModel = shareThing
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIShareThing.ShareThingCellIdentifier, forIndexPath: indexPath) as! UIShareThing
            cell.rootController = self
            cell.shareThingModel = shareThing
            return cell
        }
        
    }
    
    //MARK: Add tag from share msg
    func showConfirmAddTagAlert(tag:SharelinkTag)
    {
        let alert = UIAlertController(title: "I'm interest in \(tag.tagName)", message: "Are your sure to focus this tag?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Yes!", style: .Default){ _ in
            self.addThisTapToMyFocus(tag)
            })
        alert.addAction(UIAlertAction(title: "Ummm!", style: .Cancel){ _ in
            self.cancelAddTap(tag)
            })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelAddTap(tag:SharelinkTag)
    {
        
    }
    
    func addThisTapToMyFocus(tag:SharelinkTag)
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        let newTag = SharelinkTag()
        newTag.tagName = tag.tagName
        newTag.tagColor = tag.tagColor
        newTag.isFocus = "\(true)"
        newTag.data = tag.data
        tagService.addSharelinkTag(newTag){ (isSuc) -> Void in
            if isSuc
            {
                self.view.makeToast(message: "focus successful!")
            }else
            {
                self.view.makeToast(message: "focus tag error , please check your network")
            }
        }
        
    }
    
}
