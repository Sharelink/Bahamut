//
//  LinkedUserListController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

//MARK: LinkedUserListController
class LinkedUserListController: UITableViewController
{

    var userListModel:[(latinLetter:String , items:[Sharelinker])] = [(latinLetter:String , items:[Sharelinker])](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    var linkMessageModel:[LinkMessage] = [LinkMessage]()
    
    private(set) var userService:UserService!{
        didSet{
            userService.addObserver(self, selector: "myLinkedUsersUpdated:", name: UserService.userListUpdated, object: nil)
            userService.addObserver(self, selector: "linkMessageUpdated:", name: UserService.linkMessageUpdated, object: nil)
            userService.addObserver(self, selector: "myLinkedUsersUpdated:", name: UserService.myUserInfoRefreshed, object: nil)
            userService.addObserver(self, selector: "newLinkMessageUpdated:", name: UserService.newLinkMessageUpdated, object: nil)
        }
    }
    
    var tabBarBadgeValue:Int = 0{
        didSet{
            self.navigationController?.tabBarItem.badgeValue = tabBarBadgeValue > 0 ? "\(tabBarBadgeValue)" : nil
        }
    }
    
    deinit
    {
        if userService != nil
        {
            userService.removeObserver(self)
        }
    }
    
    func myLinkedUsersUpdated(sender:AnyObject)
    {
        let newValues = userService.myLinkedUsers
        let dict = userService.getUsersDivideWithLatinLetter(newValues)
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.userListModel = dict
        }
        
    }
    
    func newLinkMessageUpdated(a:NSNotification)
    {
        if let newMsgCnt = a.userInfo?[UserServiceNewLinkMessageCount] as? Int
        {
            self.tabBarItem.badgeValue = "\(newMsgCnt)"
        }
    }
    
    func linkMessageUpdated(sender:AnyObject)
    {
        dispatch_async(dispatch_get_main_queue()){()->Void in
            if let newValues = self.userService.linkMessageList
            {
                self.linkMessageModel = newValues
            }
            self.tableView.reloadData()
        }
        
    }
    
    func refresh()
    {
        userService.refreshMyLinkedUsers()
        myLinkedUsersUpdated(userService)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeNavigationBarColor()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let uiview = UIView()
        uiview.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = uiview
        self.userService = ServiceContainer.getService(UserService)
        self.tabBarBadgeValue = 0
        refresh()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tabBarBadgeValue = 0
        tableView.reloadData()
    }
    
    @IBAction func addNewLink(sender: AnyObject)
    {
        let user = ServiceContainer.getService(UserService).myUserModel
        let defaultIconPath = NSBundle.mainBundle().pathForResource("headImage", ofType: "png", inDirectory: "ChatAssets/photo")
        let userHeadIconPath = PersistentManager.sharedInstance.getImageFilePath(user.avatarId)
        let publishContent = ShareSDK.content("\(user.nickName) Invite You Join Sharelink", defaultContent: "Invite You Join Sharelink", image: ShareSDK.imageWithPath(userHeadIconPath ?? defaultIconPath), title: "Sharelink", url: "http://app.sharelink.online", description: nil, mediaType: SSPublishContentMediaTypeApp)
        
        let container = ShareSDK.container()
        container.setIPadContainerWithBarButtonItem(sender as? UIBarButtonItem, arrowDirect: .Down)
        ShareSDK.showShareActionSheet(container, shareList: nil, content: publishContent, statusBarTips: true, authOptions: nil, shareOptions: nil) { (type, state, statusInfo, error, end) -> Void in
            if (state == SSResponseStateSuccess)
            {
                NSLog("share success");
            }
            else if (state == SSResponseStateFail)
            {
                NSLog("share fail:%ld,description:%@", error.errorCode(), error.errorDescription());
            }
        }
    }
    
    @IBAction func showMyQRCode(sender: AnyObject)
    {
        let alert = UIAlertController(title: "QRCode", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Scan QRCode", style: .Destructive) { _ in
            self.userService.showScanQRViewController(self.navigationController!)
            })
        alert.addAction(UIAlertAction(title: "My QRCode", style: .Destructive) { _ in
            self.userService.showMyQRViewController(self.navigationController!,sharelinkUserId: self.userService.myUserId ,avataImage: nil)
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ _ in})
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    var indexOfUserList:Int{
        return linkMessageModel.count > 0 ? 1 : 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        //asking list,talking list + userlist.count
        return indexOfUserList + userListModel.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0 && linkMessageModel.count > 0
        {
            return linkMessageModel.count
        }else
        {
            return userListModel[section - indexOfUserList].items.count
        }
        
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, 23, 23))
        headerView.backgroundColor = UIColor(colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        let label = UILabel(frame: CGRectMake(7, 0, 23, 23))
        headerView.addSubview(label)
        
        if section == 0 && linkMessageModel.count > 0
        {
            label.text = "Sharelinks"
        }else
        {
            label.text = userListModel[section - indexOfUserList].latinLetter
        }
        label.sizeToFit()
        return headerView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && linkMessageModel.count > 0
        {
            let model = linkMessageModel[indexPath.row]
            if model.type == LinkMessageType.AskLink.rawValue
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListAskingLinkCell.cellIdentifier, forIndexPath: indexPath) as! UIUserListAskingLinkCell
                cell.model = model
                cell.rootController = self
                return cell
            }else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListMessageCell.cellIdentifier, forIndexPath: indexPath) as! UIUserListMessageCell
                cell.model = model
                cell.rootController = self
                return cell
            }
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListCell.cellIdentifier, forIndexPath: indexPath)
            let userModel = userListModel[indexPath.section - indexOfUserList].items[indexPath.row] as Sharelinker
            
            if let userCell = cell as? UIUserListCell
            {
                userCell.userModel = userModel
                userCell.rootController = self
            }
            return cell
        }
    }
}