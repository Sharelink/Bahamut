//
//  ChatRoomListViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class ChatRoomListCell: UITableViewCell
{
    var iconFilePath:String!{
        didSet{
            if iconView != nil{
                ServiceContainer.getService(FileService).setHeadIcon(iconView, iconFileId: iconFilePath)
            }
        }
    }
    var title:String!{
        didSet{
            titleLabel.text = title
        }
    }
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = title
        }
    }
    @IBOutlet weak var iconView: UIImageView!{
        didSet{
            iconView.layer.cornerRadius = 3
            ServiceContainer.getService(FileService).setHeadIcon(iconView, iconFileId: iconFilePath)
        }
    }
    static let cellReusableIdentifier = "chatRoomListCell"
}

class ChatRoomListViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate{

    var chatModels:[ChatModel]!{
        didSet{
            if self.roomListTableView != nil
            {
                roomListTableView.reloadData()
            }
        }
    }
    
    var shareChat:ShareChatHub!{
        didSet{
            chatModels = shareChat.getSortChats()
        }
    }
    
    @IBOutlet weak var roomListTableView: UITableView!{
        didSet{
            roomListTableView.dataSource = self
            roomListTableView.delegate = self
        }
    }
    var rootController:ChatViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(ChatRoomListCell.cellReusableIdentifier, forIndexPath: indexPath) as! ChatRoomListCell
        let model = chatModels[indexPath.row]
        cell.title = model.chatTitle
        cell.iconFilePath = model.chatIcon
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatModels.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let model = chatModels[indexPath.row]
        rootController.currentChatModel = model
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if chatModels == nil
        {
            return 0
        }
        return chatModels == nil ? 0 : 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
