//
//  ShareThingsListController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class ShareThingsListController: UITableViewController
{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        self.shareService = ServiceContainer.getService(ShareService)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh(self.refreshControl!)
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
    
    @IBOutlet weak var bottomIndicatorView: UIActivityIndicatorView!{
        didSet{
            bottomIndicatorView.hidden = true
        }
    }
    
    @IBAction func refresh(sender: UIRefreshControl)
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
            sender.endRefreshing()
        }
    }
    
    @IBAction func tag(sender: AnyObject)
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        let allTagModels = tagService.getMyAllTags()
        tagService.showTagExplorerController(self.navigationController!, tags: tagService.getUserTagsResourceItemModels(allTagModels))
    }
    
    @IBAction func userSetting(sender:AnyObject)
    {
        ServiceContainer.getService(UserService).showMyDetailView(self.navigationController!)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView)
    {
        if bottomIndicatorView != nil && bottomIndicatorView.hidden == true && scrollView.contentOffset.y > 0
        {
            loadNextPage()
        }
    }
    
    func loadNextPage()
    {
        if shareThings.count == 0 || bottomIndicatorView.hidden == false
        {
            return
        }
        self.bottomIndicatorView.hidden = false
        var startIndex = 0
        for list in shareThings
        {
            startIndex += list.count
        }
        print("request")
        self.shareService.getNextPageShareThings(startIndex, pageNum: 20) { (results) -> Void in
            print("return")
            if results.count > 0
            {
                self.shareThings.append(results)
            }else{
                self.view.makeToast(message: "No More Things")
            }
            self.bottomIndicatorView.hidden = true
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
        if isNetworkError
        {
            return 42
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if isNetworkError
        {
            let headerView = UIView()
            let msgLabel = UILabel()
            msgLabel.font = UIFont.systemFontOfSize(14, weight: 0.3)
            msgLabel.text = "Some network things happened~"
            msgLabel.textAlignment = .Center
            msgLabel.textColor = UIColor.redColor()
            msgLabel.sizeToFit()
            headerView.bounds = CGRectMake(0, 0, tableView.bounds.width, 42)
            msgLabel.center.x = tableView.center.x
            msgLabel.center.y = headerView.bounds.height / 2
            headerView.addSubview(msgLabel)
            headerView.backgroundColor = UIColor.lightGrayColor()
            return headerView
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
