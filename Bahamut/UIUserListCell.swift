//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

import ChatFramework

class UIUserListMessageCell: UITableViewCell
{
    
    static let cellIdentifier:String = "UIUserListMessageCell"
    var model:LinkMessage!{
        didSet{
            update()
        }
    }
    
    var rootController:LinkedUserListController!
    @IBOutlet weak var noteNameLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!{
        didSet{
            avatar.layer.cornerRadius = 3.0
            avatar.userInteractionEnabled = true
            avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func Ok(sender: AnyObject)
    {
        rootController.userService.deleteLinkMessage(model.id)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        if let avatarId = model.avatar
        {
            let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
            UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [avatarId],imageFileFetcher: imageFileFetcher)
        }else
        {
            UUImageAvatarBrowser.showImage(self.avatar)
        }
    }
    
    private func update()
    {
        noteNameLabel.text = model.sharelinkerNick
        timeLabel.text = DateHelper.stringToDateTime(model.time).toFriendlyString()
        messageLabel.text = model.isAcceptAskLinkMessage() ? NSLocalizedString("USER_ACCEPT_YOUR_LINK", comment: "") : model.message
        ServiceContainer.getService(FileService).setAvatar(avatar, iconFileId: model.avatar)
    }
}

class UIUserListAskingLinkCell: UITableViewCell
{
    static let cellIdentifier:String = "UserAskLinkCell"
    var model:LinkMessage!{
        didSet{
            update()
        }
    }
    var rootController:LinkedUserListController!
    @IBOutlet weak var avatar: UIImageView!{
        didSet{
            avatar.layer.cornerRadius = 3.0
            avatar.userInteractionEnabled = true
            avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    @IBOutlet weak var userNickLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func ignore(sender: AnyObject)
    {
        rootController.userService.deleteLinkMessage(model.id)
    }
    
    @IBAction func accept(sender: AnyObject)
    {
        rootController.userService.showLinkConfirmViewController(self.rootController.navigationController!, linkMessage: self.model)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
        UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [model.avatar ?? ImageAssetsConstants.defaultAvatar],imageFileFetcher: imageFileFetcher)
    }
    
    private func update()
    {
        userNickLabel.text = "\(model.sharelinkerNick)"
        messageLabel.text = String(format: NSLocalizedString("ASKING_FOR_A_LINK", comment: "asking for a link"),model.sharelinkerNick!)
        ServiceContainer.getService(FileService).setAvatar(avatar, iconFileId: model.avatar)
    }
    
}

class UIUserListCell: UITableViewCell
{
    static let cellIdentifier:String = "UserCell"
    
    var userModel:Sharelinker!{
        didSet{
            update()
        }
    }
    
    @IBOutlet weak var levelLabel: UILabel!{
        didSet{
            levelLabel.userInteractionEnabled = true
            levelLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showLevelRule:"))
        }
    }
    var rootController:LinkedUserListController!{
        didSet{
            if oldValue == nil
            {
                self.userInteractionEnabled = true
                self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showProfile:"))
            }
        }
    }
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 3.0
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    
    @IBOutlet weak var userNickTextField: UILabel!
    
    func showLevelRule(_:UIGestureRecognizer)
    {
        let title = NSLocalizedString("LEVEL_RULE_TITLE", comment: "Level Rule")
        let msg = NSLocalizedString("LEVEL_RULE_DESC", comment:
            "1.One Share Worth 1 Point\n2.Your Share Be Vote One Time Worth 1 Point\n3Your Share Be Reshare Worth 2 Point\nYou Rank Caculate By Your Points")
        self.rootController.showAlert(title, msg: msg, actions: ALERT_ACTION_I_SEE)
    }
    
    func showProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userProfile: self.userModel)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        if let avatarId = userModel?.avatarId
        {
            let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
            UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [avatarId],imageFileFetcher: imageFileFetcher)
        }else
        {
            UUImageAvatarBrowser.showImage(self.avatarImageView)
        }
    }
    
    func update()
    {
        userNickTextField.text = userModel.getNoteName()
        levelLabel.text = "Lv.\(userModel.level ?? 1)"
        updateAvatar()
    }
    
    func updateAvatar()
    {
        let fileService = ServiceContainer.getService(FileService)
        fileService.setAvatar(self.avatarImageView, iconFileId: userModel.avatarId)
    }

}