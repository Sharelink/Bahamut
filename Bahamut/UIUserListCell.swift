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
    @IBOutlet weak var avatar: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    private func update()
    {
        let user = ServiceContainer.getService(UserService).getUser(model.userId)
        noteNameLabel.text = user?.noteName
        timeLabel.text = model.time.toFriendlyString()
        messageLabel.text = model.message
        avatar.image = PersistentManager.sharedInstance.getImage(user?.avatarId)
    }
}

class UIUserListAskingLinkCell: UITableViewCell
{
    static let cellIdentifier:String = "UserAskLinkCell"
    var user:ShareLinkUser!
    @IBOutlet weak var avatar: UIImageView!
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
        avatar.image = PersistentManager.sharedInstance.getImage(user?.avatarId)
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
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 3.0
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
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
    
    func showAvatar(_:UIGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
        UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [userModel.avatarId ?? ImageAssetsConstants.defaultAvatar],imageFileFetcher: imageFileFetcher)
    }
    
    func update()
    {
        userNickTextField.text = userModel.noteName ?? userModel.nickName
        levelLabel.text = "Lv.\(userModel.level ?? 1)"
        updateAvatar()
    }
    
    func updateAvatar()
    {
        let fileService = ServiceContainer.getService(FileService)
        fileService.setAvatar(self.avatarImageView, iconFileId: userModel.avatarId)
    }

}