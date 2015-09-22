//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class UIUserListMessageCell: UITableViewCell
{
    
    static let cellIdentifier:String = "UIUserListMessageCell"
    var model:UserMessageListItem!{
        didSet{
            update()
        }
    }
    @IBOutlet weak var noteNameLabel: UILabel!
    @IBOutlet weak var headIcon: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    private func update()
    {
        let user = ServiceContainer.getService(UserService).getUser(model.userId)
        noteNameLabel.text = user?.noteName
        timeLabel.text = model.time.toFriendlyString()
        messageLabel.text = model.message
        headIcon.image = PersistentManager.sharedInstance.getImage(user?.headIconId)
    }
}

class UIUserListAskingLinkCell: UITableViewCell
{
    static let cellIdentifier:String = "UserAskLinkCell"
    var user:ShareLinkUser!
    @IBOutlet weak var headIcon: UIImageView!
    @IBOutlet weak var userNickLabel: UILabel!
    
    @IBAction func ignore(sender: AnyObject)
    {
    }
    
    @IBAction func accept(sender: AnyObject)
    {
        let userService = ServiceContainer.getService(UserService)
        userService.acceptUserLink(user.userId, noteName: user.nickName){ isSuc in
            
        }
    }
    
    private func update()
    {
        userNickLabel.text = "\(user?.nickName) asking for a link"
        headIcon.image = PersistentManager.sharedInstance.getImage(user?.headIconId)
    }
    
}

class UIUserListCell: UITableViewCell
{
    static let cellIdentifier:String = "UserCell"
    
    var userModel:ShareLinkUser!{
        didSet{
            update()
        }
    }
    
    //var sharelinkTags:[SharelinkTag]!
    
    @IBOutlet weak var levelLabel: UILabel!
    var rootController:UIViewController!
    @IBOutlet weak var headIconImageView: UIImageView!{
        didSet{
            headIconImageView.layer.cornerRadius = 3.0
            headIconImageView.userInteractionEnabled = true
            headIconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHeadIcon:"))
        }
    }
    
    @IBOutlet weak var userNickTextField: UILabel!{
        didSet{
            userNickTextField.userInteractionEnabled = true
            userNickTextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showProfile:"))
        }
    }
    
    func showProfile(_:UIGestureRecognizer)
    {
        ServiceContainer.getService(UserService).showUserProfileViewController(self.rootController.navigationController!, userProfile: self.userModel)
    }
    
    func showHeadIcon(_:UIGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
        UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [userModel.headIconId ?? ImageAssetsConstants.defaultHeadIcon],imageFileFetcher: imageFileFetcher)
    }
    
    func update()
    {
        userNickTextField.text = userModel.noteName ?? userModel.nickName
        levelLabel.text = "Lv.\(userModel.level ?? 1)"
        updateHeadIcon()
    }
    
    func updateHeadIcon()
    {
        let fileService = ServiceContainer.getService(FileService)
        fileService.setHeadIcon(self.headIconImageView, iconFileId: userModel.headIconId)
    }

}