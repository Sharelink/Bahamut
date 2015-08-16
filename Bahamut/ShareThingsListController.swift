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
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if bottomIndicatorView != nil && bottomIndicatorView.hidden == true{
            loadNextPage()
        }
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
        self.bottomIndicatorView.hidden = false
        self.shareService.getNextPageShareThings(startIndex, pageNum: 20) { (results) -> Void in
            if results.count > 0
            {
                self.shareThings.append(results)
            }else{
                self.view.makeToast(message: "the last page")
            }
            self.bottomIndicatorView.hidden = true
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return shareThings.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return shareThings[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
