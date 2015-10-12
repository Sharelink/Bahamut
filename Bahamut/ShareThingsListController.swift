//
//  ShareThingsListController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import MJRefresh
import BBBadgeBarButtonItem

class ShareThingsListController: UITableViewController
{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
        initRefresh()
        initConnectionToChicago()
        changeNavigationBarColor()
        self.shareService = ServiceContainer.getService(ShareService)
        
    }
    
    private func initConnectionToChicago()
    {
        ChicagoClient.sharedInstance.addObserver(self, selector: "chicagoClientStateChanged:", name: ChicagoClientStateChanged, object: nil)
    }
    
    deinit{
        ChicagoClient.sharedInstance.removeObserver(self)
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
        tableView.header = MJRefreshNormalHeader(){self.refresh()}
        tableView.footer = MJRefreshAutoNormalFooter(){self.loadNextPage()}
        tableView.footer.automaticallyHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
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
        self.shareService.getNewShareThings { (haveChange) -> Void in
            if !haveChange{
                return
            }
            self.shareThings.removeAll(keepCapacity: true)
            let newValues = self.shareService.getShareThings(0)
            dispatch_async(dispatch_get_main_queue()){()->Void in
                self.shareThings.insert(newValues, atIndex: 0)
                self.tableView.reloadData()
            }
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
        ServiceContainer.getService(UserService).showMyDetailView(self.navigationController!)
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
        if ChicagoClient.sharedInstance.clientState != ChicagoClientState.Connected
        {
            return 35
        }
        return 0
    }
    
    var stateHeaderView:UIClientStateHeader!
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cstate = ChicagoClient.sharedInstance.clientState
        if cstate != ChicagoClientState.Connected
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
    
}
