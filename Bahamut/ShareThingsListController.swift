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
    struct Constants
    {
        static let ShareThingIdentifier = "ShareThing"
        static let NetworkErrorCellIdentifier = "networkErrorCell"
    }
    
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
    
    var isNetworkError:Bool = false
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
    
    @IBAction func userSetting(sender:AnyObject)
    {
        let service = ServiceContainer.getService(AccountService)
        service.logout { (msg) -> Void in
            let fileSvr = ServiceContainer.getService(FileService)
            fileSvr.clearUserDatas()
            self.navigationController?.popToRootViewControllerAnimated(false)
            MainNavigationController.start(self, msg: msg)
        }
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
        return isNetworkError ? shareThings.count + 1 : shareThings.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if isNetworkError
        {
            return section == 0 ? 1 :  shareThings[section + 1].count
        }
        return shareThings[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isNetworkError && indexPath.section == 0
        {
            let errorCell = tableView.dequeueReusableCellWithIdentifier(Constants.NetworkErrorCellIdentifier, forIndexPath: indexPath)
            return errorCell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ShareThingIdentifier, forIndexPath: indexPath)
        let shareThing = shareThings[indexPath.section][indexPath.row] as ShareThing
        if let shareThingUI = cell as? UIShareThing
        {
            shareThingUI.rootController = self

            shareThingUI.shareThingModel = shareThing
        }
        return cell
    }
    
}
