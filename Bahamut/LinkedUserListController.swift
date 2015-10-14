//
//  LinkedUserListController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class LinkedUserListController: UITableViewController
{

    var userListModel:[(latinLetter:String , items:[ShareLinkUser])] = [(latinLetter:String , items:[ShareLinkUser])](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    var askingListModel:[ShareLinkUser] = [ShareLinkUser](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    var talkingListModel:[UserMessageListItem] = [UserMessageListItem](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    private var messageService:MessageService!{
        didSet{
            
        }
    }
    
    private var userService:UserService!{
        didSet{
            userService.addObserver(self, selector: "myLinkedUsersUpdated:", name: UserService.userListUpdated, object: nil)
            userService.addObserver(self, selector: "askingLinkUserListUpdated:", name: UserService.askingLinkUserListUpdated, object: nil)
        }
    }
    
    deinit
    {
        userService.removeObserver(self)
        messageService.removeObserver(self)
    }
    
    func myLinkedUsersUpdated(sender:AnyObject)
    {
        let newValues = userService.myLinkedUsers
        let dict = userService.getUsersDivideWithLatinLetter(newValues)
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.userListModel = dict
        }
        
    }
    
    func askingLinkUserListUpdated(sender:AnyObject)
    {
        if let newValues = userService.askingLinkUserList
        {
            dispatch_async(dispatch_get_main_queue()){()->Void in
                self.askingListModel = newValues
            }
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
        refresh()
        headerGesture = UITapGestureRecognizer(target: self, action: "tapHeader:")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func addNewLink(sender: AnyObject)
    {
        userService.showScanQRViewController(self.navigationController!)
    }
    
    @IBAction func showMyQRCode(sender: AnyObject)
    {
        if let sharelinkUserId = userService.myUserId
        {
            userService.showMyQRViewController(self.navigationController!,sharelinkUserId: sharelinkUserId ,avataImage: PersistentManager.sharedInstance.getImage(userService.myUserModel.avatarId))
        }
    }
    
    var headerGesture:UITapGestureRecognizer!
    func tapHeader(tap:UITapGestureRecognizer)
    {
        //TODO:
        
        print("header")
    }
    
    var indexOfUserList:Int{
        return (askingListModel.count > 0 ? 1:0) + (talkingListModel.count > 0 ? 1:0)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        //asking list,talking list + userlist.count
        return indexOfUserList + userListModel.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0 && askingListModel.count > 0
        {
            return askingListModel.count
        }else if section <= 1 && talkingListModel.count > 0
        {
            return talkingListModel.count
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
        
        if section == 0 && askingListModel.count > 0
        {
            if askingListModel.count > 0
            {
                label.text = "Sharelinks ask for link"
            }else
            {
                return nil
            }
        }else if section  <= 1 && talkingListModel.count > 0
        {
            if talkingListModel.count > 0
            {
               label.text = "talking"
            }else
            {
                return nil
            }
        }else
        {
            label.text = userListModel[section - indexOfUserList].latinLetter
            headerView.addGestureRecognizer(headerGesture)
        }
        label.sizeToFit()
        return headerView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && askingListModel.count > 0
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListAskingLinkCell.cellIdentifier, forIndexPath: indexPath) as! UIUserListAskingLinkCell
            let model = askingListModel[indexPath.row]
            cell.user = model
            return cell
            
            
        }else if indexPath.section  <= 1 && talkingListModel.count > 0
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListMessageCell.cellIdentifier, forIndexPath: indexPath) as! UIUserListMessageCell
            let model = talkingListModel[indexPath.row]
            cell.model = model
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(UIUserListCell.cellIdentifier, forIndexPath: indexPath)
            let userModel = userListModel[indexPath.section - indexOfUserList].items[indexPath.row] as ShareLinkUser
            
            if let userCell = cell as? UIUserListCell
            {
                userCell.userModel = userModel
                userCell.rootController = self
            }
            return cell
        }
    }
}