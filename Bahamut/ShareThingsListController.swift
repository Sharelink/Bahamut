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
    private(set) var messageService:ChatService!
    private(set) var notificationService:NotificationService!
    private(set) var shareService = ServiceContainer.getService(ShareService)
    private var shareThings:[ShareThing] = [ShareThing]()
    private var isShowing:Bool = false
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        userService = ServiceContainer.getService(UserService)
        fileService = ServiceContainer.getService(FileService)
        messageService = ServiceContainer.getService(ChatService)
        notificationService = ServiceContainer.getService(NotificationService)
        ChicagoClient.sharedInstance.addObserver(self, selector: #selector(ShareThingsListController.chicagoClientStateChanged(_:)), name: ChicagoClientStateChanged, object: nil)
        initTableView()
        initRefresh()
        changeNavigationBarColor()
        self.shareService = ServiceContainer.getService(ShareService)
        messageService.addObserver(self, selector: #selector(ShareThingsListController.newChatMessageReceived(_:)), name: ChatService.messageServiceNewMessageReceived, object: nil)
        shareService.addObserver(self, selector: #selector(ShareThingsListController.shareUpdatedReceived(_:)), name: ShareService.shareUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: #selector(ShareThingsListController.onServiceLogout(_:)), name: ServiceContainer.OnServicesWillLogout, object: nil)
        refresh()
    }
    
    func onServiceLogout(sender:AnyObject)
    {
        if userService != nil
        {
            ChicagoClient.sharedInstance.removeObserver(self)
            ServiceContainer.instance.removeObserver(self)
            userService.removeObserver(self)
            messageService.removeObserver(self)
            shareService.removeObserver(self)
            userService = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        isShowing = true
        MobClick.beginLogPageView("ShareThings")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        isShowing = false
        MobClick.endLogPageView("ShareThings")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if UserSetting.isAppstoreReviewing == false
        {
            #if APP_VERSION
                UserGuideStartController.startUserGuide(self)
            #endif
        }
        if shareThings.count == 0
        {
            refreshFromServer()
        }
    }
    
    deinit{
        ServiceContainer.getService(ChatService).removeObserver(self)
        ServiceContainer.getService(ShareService).removeObserver(self)
        ServiceContainer.getService(UserService).removeObserver(self)
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    //MARK: init actions
    
    private func initTableView()
    {
        tableView.separatorStyle = .None
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        tableView.tableFooterView = uiview
    }
    
    private func initRefresh()
    {
        let header = MJRefreshNormalHeader(){self.refreshFromServer()}
        let footer = MJRefreshAutoNormalFooter(){self.loadNextPage()}
        header.setTitle("RefreshHeaderIdleText".localizedString(), forState: .Idle)
        header.setTitle("RefreshHeaderPullingText".localizedString(), forState: .Pulling)
        header.setTitle("RefreshHeaderRefreshingText".localizedString(), forState: .Refreshing)
        
        footer.setTitle("MJRefreshAutoFooterIdleText".localizedString(), forState: .Idle)
        footer.setTitle("MJRefreshAutoFooterRefreshingText".localizedString(), forState: .Pulling)
        footer.setTitle("RefreshAutoFooterNoMoreDataText".localizedString(), forState: .NoMoreData)
        
        tableView.mj_header = header
        tableView.mj_footer = footer
        tableView.mj_footer.automaticallyHidden = true
        header.lastUpdatedTimeLabel?.hidden = true
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
        let newState = aNotification.userInfo![ChicagoClientCurrentState] as! Int
        let oldState = aNotification.userInfo![ChicagoClientBeforeChangedState] as! Int
        if oldState == ChicagoClientState.Connecting.rawValue && (newState == ChicagoClientState.Disconnected.rawValue || newState == ChicagoClientState.ValidatFailed.rawValue)
        {
            tableView.reloadData()
        }
    }
    
    //MARK: message
    func shareUpdatedReceived(a:NSNotification)
    {
        dispatch_after(1000, dispatch_get_main_queue()){
            self.refresh()
        }
    }
    
    func newChatMessageReceived(aNotification:NSNotification)
    {
        if let messages = aNotification.userInfo?[ChatServiceNewMessageEntities] as? [MessageEntity]
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshShareLastActiveTime(messages)
            })
        }
    }
    
    private func refreshShareLastActiveTime(messages:[MessageEntity])
    {
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
        self.refresh()
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
                    self.refresh()
                }
            })
        }
        
    }
    
    //MARK: Data refresh

    let refreshLock = NSRecursiveLock()
    func refresh()
    {
        
        dispatch_async(dispatch_get_main_queue()){
            self.refreshLock.lock()
            self.shareThings.removeAll(keepCapacity: true)
            let newValues = self.shareService.getShareThings(0,pageNum: 7)
            self.shareThings.insertContentsOf(newValues, at: 0)
            self.tableView.reloadData()
            self.refreshLock.unlock()
            self.tableView.scrollToNearestSelectedRowAtScrollPosition(.Top, animated: true)
            self.tableView.mj_footer.resetNoMoreData()
        }
    }
    
    func refreshFromServer()
    {
        self.shareService.getNewShareThings { (newShares) -> Void in
            self.tableView.mj_header.endRefreshing()
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
        self.refreshLock.lock()
        let startIndex = shareThings.count
        let shares = self.shareService.getShareThings(startIndex, pageNum: 10)
        if shares.count > 0
        {
            self.shareThings.insertContentsOf(shares, at: startIndex)
            self.tableView.mj_footer.endRefreshing()
            self.tableView.reloadData()
            self.refreshLock.unlock()
        }else
        {
            self.refreshLock.unlock()
            let loading = self.shareService.getPreviousShare({ (previousShares) -> Void in
                self.tableView.mj_footer.endRefreshing()
                if previousShares != nil && previousShares.count > 0
                {
                    self.refreshLock.lock()
                    self.shareThings.insertContentsOf(previousShares, at: startIndex)
                    self.tableView.reloadData()
                    self.refreshLock.unlock()
                }
                if self.shareService.allShareLoaded
                {
                    self.tableView.mj_footer.endRefreshingWithNoMoreData()
                }else
                {
                    self.tableView.mj_footer.resetNoMoreData()
                }
            })
            if loading == false
            {
                self.tableView.mj_footer.endRefreshing()
            }
        }
        
    }
    
    //MARK: actions
    
    func scrollTableViewToTop()
    {
        if self.shareThings.count > 0
        {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
        }
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
        let cstate = ChicagoClient.sharedInstance.clientState
        if cstate == ChicagoClientState.Disconnected || cstate == .ValidatFailed
        {
            return 35
        }
        return 0
    }
    
    var stateHeaderView:UIClientStateHeader!{
        didSet{
            stateHeaderView.initHeader()
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cstate = ChicagoClient.sharedInstance.clientState
        if cstate == ChicagoClientState.Disconnected || cstate == .ValidatFailed
        {
            if stateHeaderView == nil
            {
                stateHeaderView = UIClientStateHeader.instanceFromXib()
            }
            return stateHeaderView
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let shareThing = shareThings[indexPath.row] as ShareThing
        var cell:UIShareCell!
        if shareThing.isMessageShare()
        {
            cell = tableView.dequeueReusableCellWithIdentifier(UIShareMessage.RollMessageCellIdentifier) as! UIShareMessage
        }else if shareThing.isUserShare()
        {
            cell = tableView.dequeueReusableCellWithIdentifier(UIShareThing.ShareThingCellIdentifier) as! UIShareThing
        }else
        {
            cell = tableView.dequeueReusableCellWithIdentifier(UIShareMessage.RollMessageCellIdentifier) as! UIShareMessage
        }
        cell.rootController = self
        cell.shareModel = shareThing
        cell.update()
        return cell
    }
}
