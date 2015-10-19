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
    
    
    func newMessageReceived(aNotification:NSNotification)
    {
        if let messages = aNotification.userInfo?[MessageServiceNewMessageEntities] as? [MessageEntity]
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                self.refreshShareLastActiveTime(messages)
            })
        }
    }
    
    private func refreshShareLastActiveTime(messages:[MessageEntity])
    {
        self.tabBarItem.badgeValue = "\(messages.count)"
        var notReadyShare = [String]()
        var notReadyShareThingMsg = [String:MessageEntity]()
        for msg in messages
        {
            if let share = PersistentManager.sharedInstance.getModel(ShareThing.self, idValue: msg.shareId)
            {
                if share.lastActiveTime.dateOfString.timeIntervalSince1970 < msg.time.timeIntervalSince1970
                {
                    share.lastActiveTime = msg.time.toDateString()
                }
            }else
            {
                if notReadyShareThingMsg.keys.contains(msg.shareId) == false
                {
                    if notReadyShareThingMsg[msg.shareId]?.time.timeIntervalSince1970 < msg.time.timeIntervalSince1970
                    {
                        notReadyShareThingMsg.updateValue(msg, forKey: msg.shareId)
                    }
                    notReadyShare.append(msg.shareId)
                }else
                {
                    notReadyShareThingMsg.updateValue(msg, forKey: msg.shareId)
                }
                
            }
        }
        PersistentManager.sharedInstance.saveAll()
        self.refresh()
        shareService.getShareThings(notReadyShare, updatedCallback: { (haveChange, newValues) -> Void in
            if haveChange
            {
                for s:ShareThing in newValues
                {
                    s.lastActiveTime = notReadyShareThingMsg[s.shareId]?.time.toDateString()
                }
                PersistentManager.sharedInstance.saveAll()
                self.refresh()
            }
        })
    }
    
    func serverShareUpdated(aNotification:NSNotification)
    {
        tableView.reloadData()
    }
    
    func chicagoClientStateChanged(aNotification:NSNotification)
    {
        tableView.reloadData()
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
    var shareService = ServiceContainer.getService(ShareService)
    var shareThings:[[ShareThing]] = [[ShareThing]]()
    
    func refresh()
    {
        self.shareThings.removeAll(keepCapacity: true)
        let newValues = self.shareService.getShareThings(0)
        self.shareThings.insert(newValues, atIndex: 0)
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.tableView.reloadData()
        }
    }
    
    func refreshFromServer()
    {
        self.shareService.getNewShareThings { (haveChange) -> Void in
            if !haveChange{
                return
            }
            self.refresh()
            self.tableView.header.endRefreshing()
        }
    }
    
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
    
    func loadNextPage()
    {
        if shareThings.count == 0
        {
            return
        }
        var startIndex = 0
        for list in shareThings
        {
            startIndex += list.count
        }
        self.shareService.getNextPageShareThings(startIndex, pageNum: 10) { (results) -> Void in
            self.tableView.footer.endRefreshing()
            if results.count > 0
            {
                self.shareThings.append(results)
            }else{
                self.tableView.footer.noticeNoMoreData()
            }
            
        }
    }
    
    //MARK: tableView delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if shareThings.count > section
        {
            return shareThings[section].count
        }
        return 0
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
    
    func reconnectChicagoClient(_:UIGestureRecognizer)
    {
        ChicagoClient.sharedInstance.reConnect()
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
        
        let shareThing = shareThings[indexPath.section][indexPath.row] as ShareThing
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
