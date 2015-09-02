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
    var userListModel:[(String , [ShareLinkUser])] = [(String , [ShareLinkUser])](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    private var userService:UserService!
    private var userTagService:UserTagService!
    
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
        let newValues = self.userService.myLinkedUsers
        let dict = self.userService.getUsersDivideWithLatinLetter(newValues)
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.userListModel = dict
        }
    }
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        self.userService = ServiceContainer.getService(UserService)
        self.userTagService = ServiceContainer.getService(UserTagService)
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return userListModel.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return userListModel[section].1.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section:Int) -> String?  {
        
        return userListModel[section].0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.UserIdentifier, forIndexPath: indexPath) 
        let userModel = userListModel[indexPath.section].1[indexPath.row] as ShareLinkUser
        
        if let userCell = cell as? UIUserListCell
        {
            userCell.userModel = userModel
            userCell.sharelinkTags = userTagService.getAUsersTags(userModel.userId)
            userCell.rootController = self
        }
        return cell
    }
}