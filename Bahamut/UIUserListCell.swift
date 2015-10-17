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
    var model:LinkMessage!{
        didSet{
            update()
        }
    }
    
    var rootController:LinkedUserListController!
    @IBOutlet weak var noteNameLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func Ok(sender: AnyObject)
    {
        rootController.userService.deleteLinkMessage(model.id)
    }
    
    private func update()
    {
        noteNameLabel.text = model.sharelinkerNick
        timeLabel.text = DateHelper.stringToDate(model.time).toFriendlyString()
        messageLabel.text = model.message
        ServiceContainer.getService(FileService).setAvatar(avatar, iconFileId: model.avatar)
    }
}

class UIUserListAskingLinkCell: UITableViewCell
{
    static let cellIdentifier:String = "UserAskLinkCell"
    var model:LinkMessage!
    var rootController:LinkedUserListController!
    @IBOutlet weak var avatar: UIImageView!
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
                self.rootController.view.makeToast(message: "acceptUserLink error")
            }
        }
    }
    
    private func update()
    {
        userNickLabel.text = "\(model.sharelinkerNick)"
        messageLabel.text = "asking for a link"
        avatar.image = PersistentManager.sharedInstance.getImage(model.avatar)
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