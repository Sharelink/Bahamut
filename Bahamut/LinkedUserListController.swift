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
    var talkingUserList:[ShareLinkUser]!
    var askingLinkUserList:[ShareLinkUser]!
    var userListModel:[(latinLetter:String , items:[ShareLinkUser])] = [(latinLetter:String , items:[ShareLinkUser])](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    private var userService:UserService!
    private var sharelinkTagService:SharelinkTagService!
    
    struct Constants
    {
        static let UserIdentifier = "UserCell"
    }
    
    func refresh()
    {
        if userService.myLinkedUsers == nil{
            userService.refreshMyLinkedUsers({ (isSuc, msg) -> Void in
                self.refreshUserList()
            })
        }else{
            refreshUserList()
        }
        
    }
    
    private func refreshUserList(){
        if let newValues = self.userService.myLinkedUsers
        {
            let dict = self.userService.getUsersDivideWithLatinLetter(newValues)
            dispatch_async(dispatch_get_main_queue()){()->Void in
                self.userListModel = dict
            }
        }else{
            view.makeToast(message: "Data Error", duration: 0.0, position: HRToastPositionCenter)
        }
        
    }
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        self.userService = ServiceContainer.getService(UserService)
        self.sharelinkTagService = ServiceContainer.getService(SharelinkTagService)
        headerGesture = UITapGestureRecognizer(target: self, action: "tapHeader:")
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
    }
    
    @IBAction func addNewLink(sender: AnyObject)
    {
        userService.showScanQRViewController(self.navigationController!)
    }
    
    
    @IBAction func showMyQRCode(sender: AnyObject)
    {
        if let sharelinkUserId = userService.myUserId
        {
            userService.showMyQRViewController(self.navigationController!,sharelinkUserId: sharelinkUserId ,avataImage: PersistentManager.sharedInstance.getImage(userService.myUserModel.headIconId))
        }
    }
    
    var headerGesture:UITapGestureRecognizer!
    func tapHeader(tap:UITapGestureRecognizer)
    {
        //TODO:
        
        print("header")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return userListModel.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return userListModel[section].items.count
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, 23, 23))
        headerView.backgroundColor = UIColor.lightGrayColor()
        let label = UILabel(frame: CGRectMake(7, 0, 23, 23))
        label.text = userListModel[section].latinLetter
        headerView.addSubview(label)
        headerView.addGestureRecognizer(headerGesture)
        return headerView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.UserIdentifier, forIndexPath: indexPath) 
        let userModel = userListModel[indexPath.section].1[indexPath.row] as ShareLinkUser
        
        if let userCell = cell as? UIUserListCell
        {
            userCell.userModel = userModel
            userCell.sharelinkTags = sharelinkTagService.getAUsersTags(userModel.userId)
            userCell.rootController = self
        }
        return cell
    }
}