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
    private(set) var notificationService:NotificationService!
    private(set) var shareService = ServiceContainer.getService(ShareService)
    private var shareThings:[ShareThing] = [ShareThing]()
    private var isShowing:Bool = false
    private var userGuide:UserGuide!
    override func viewDidLoad() {
        super.viewDidLoad()
        initTabBarBadgeValue()
        initUserGuide()
        userService = ServiceContainer.getService(UserService)
        fileService = ServiceContainer.getService(FileService)
        messageService = ServiceContainer.getService(MessageService)
        notificationService = ServiceContainer.getService(NotificationService)
        ChicagoClient.sharedInstance.addObserver(self, selector: "chicagoClientStateChanged:", name: ChicagoClientStateChanged, object: nil)
        initTableView()
        initRefresh()
        changeNavigationBarColor()
        self.shareService = ServiceContainer.getService(ShareService)
        messageService.addObserver(self, selector: "newChatMessageReceived:", name: MessageService.messageServiceNewMessageReceived, object: nil)
        ChicagoClient.sharedInstance.addChicagoObserver(shareUpdatedNotifyRoute, observer: self, selector: "shareUpdatedMsgReceived:")
        refresh()
    }
    
    deinit{
        ServiceContainer.getService(MessageService).removeObserver(self)
        ServiceContainer.getService(ShareService).removeObserver(self)
        ServiceContainer.getService(UserService).removeObserver(self)
        ChicagoClient.sharedInstance.removeObserver(self)
    }
    
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(BahamutSetting.lang, viewName: "Share")
        self.userGuide.initGuide(self, userId: BahamutSetting.userId, guideImgs: guideImgs)
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
        let header = MJRefreshNormalHeader(){self.refreshFromServer()}
        let footer = MJRefreshAutoNormalFooter(){self.loadNextPage()}
        header.setTitle(NSLocalizedString("RefreshHeaderIdleText", comment: "下拉可以刷新"), forState: MJRefreshStateIdle)
        header.setTitle(NSLocalizedString("RefreshHeaderPullingText", comment: "松开立即刷新"), forState: MJRefreshStatePulling)
        header.setTitle(NSLocalizedString("RefreshHeaderRefreshingText", comment: "正在刷新数据中..."), forState: MJRefreshStateRefreshing)
        
        footer.setTitle(NSLocalizedString("MJRefreshAutoFooterIdleText", comment: "点击或上拉加载更多"), forState: MJRefreshStateIdle)
        footer.setTitle(NSLocalizedString("MJRefreshAutoFooterRefreshingText", comment: "正在加载更多的数据..."), forState: MJRefreshStatePulling)
        footer.setTitle(NSLocalizedString("RefreshAutoFooterNoMoreDataText", comment: "已经全部加载完毕"), forState: MJRefreshStateNoMoreData)
        
        tableView.mj_header = header
        tableView.mj_footer = footer
        tableView.mj_footer.automaticallyHidden = true
        header.lastUpdatedTimeLabel?.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = true
        }
        isShowing = true
        MobClick.beginLogPageView("ShareThings")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        isShowing = false
        MobClick.endLogPageView("ShareThings")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        userGuide.showGuideControllerPresentFirstTime()
        tabBarBadgeValue = 0
        if shareThings.count == 0
        {
            refreshFromServer()
        }
    }
    
    func initTabBarBadgeValue()
    {
        tabBarBadgeValue = NSUserDefaults.standardUserDefaults().integerForKey("\(BahamutSetting.lastLoginAccountId)ShareThingsListBadge")
    }
    
    var tabBarBadgeValue:Int!{
        didSet{
            self.navigationController?.tabBarItem.badgeValue = tabBarBadgeValue > 0 ? "\(tabBarBadgeValue)" : nil
            NSUserDefaults.standardUserDefaults().setInteger(tabBarBadgeValue, forKey: "\(BahamutSetting.lastLoginAccountId)ShareThingsListBadge")
        }
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
    func shareUpdatedMsgReceived(a:NSNotification)
    {
        dispatch_after(1000 * 7, dispatch_get_main_queue()){
            self.shareService.getNewShareMessageFromServer(){ msgs in
                if self.isShowing == false
                {
                    self.tabBarBadgeValue = self.tabBarBadgeValue + msgs.count
                }
                self.refresh()
                self.notificationService.playHintSound()
            }
        }
    }
    
    func chicagoClientStateChanged(aNotification:NSNotification)
    {
        tableView.reloadData()
    }
    
    //MARK: message
    func newChatMessageReceived(aNotification:NSNotification)
    {
        if let messages = aNotification.userInfo?[MessageServiceNewMessageEntities] as? [MessageEntity]
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshShareLastActiveTime(messages)
            })
            if messages.count > 0
            {
                self.notificationService.playReceivedMessageSound()
            }
        }
    }
    
    private func refreshShareLastActiveTime(messages:[MessageEntity])
    {
        self.tabBarBadgeValue = tabBarBadgeValue + messages.count
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
            stateHeaderView.initHeader()
        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let shareCell = cell as? UIShareThing
        {
            shareCell.update()
        }
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cstate = ChicagoClient.sharedInstance.clientState
        if cstate != ChicagoClientState.Validated
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
        if shareThing.isMessageShare()
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIShareMessage.RollMessageCellIdentifier, forIndexPath: indexPath) as! UIShareMessage
            cell.rootController = self
            cell.shareThingModel = shareThing
            return cell
        }else if shareThing.isShareFilm()
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIShareThing.ShareThingCellIdentifier, forIndexPath: indexPath) as! UIShareThing
            cell.rootController = self
            cell.shareThingModel = shareThing
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIShareMessage.RollMessageCellIdentifier, forIndexPath: indexPath) as! UIShareMessage
            cell.rootController = self
            cell.shareThingModel = shareThing
            return cell
        }
        
    }
    
}
