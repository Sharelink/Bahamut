//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import SharelinkSDK

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
        let imageFileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Image)
        UIImagePlayerController.showImagePlayer(self.rootController, imageUrls: [model.avatar ?? ImageAssetsConstants.defaultAvatar],imageFileFetcher: imageFileFetcher)
    }
    
    private func update()
    {
        noteNameLabel.text = model.sharelinkerNick
        timeLabel.text = DateHelper.stringToDateTime(model.time).toFriendlyString()
        messageLabel.text = model.message
        ServiceContainer.getService(FileService).setAvatar(avatar, iconFileId: model.avatar)
    }
}

class UIUserListAskingLinkCell: UITableViewCell
{
    static let cellIdentifier:String = "UserAskLinkCell"
    var model:LinkMessage!
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
        let userService = rootController.userService
        userService.acceptUserLink(model.sharelinkerId, noteName: model.sharelinkerNick){ isSuc in
            if isSuc
            {
                userService.deleteLinkMessage(self.model.id)
            }else
            {
                self.rootController.view.makeToast(message: NSLocalizedString("ACCEPT_USER_LINK_FAILED", comment: ""))
            }
        }
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
        avatar.image = PersistentManager.sharedInstance.getImage(model.avatar)
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
    
    //var sharelinkTags:[SharelinkTag]!
    
    @IBOutlet weak var levelLabel: UILabel!
    var rootController:LinkedUserListController!
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
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userProfile: self.userModel)
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