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
    
    struct Constants
    {
        static let UserIdentifier = "UserCell"
    }
    
    func refresh()
    {
        let newValues = userService.myLinkedUsers
        let dict = userService.getUsersDivideWithLatinLetter(newValues)
        dispatch_async(dispatch_get_main_queue()){()->Void in
            self.userListModel = dict
        }
    }
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        self.userService = ServiceContainer.getService(UserService)
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
        if let userCell = cell as? UIUser
        {
            userCell.userModel = userModel
        }
        return cell
    }
}