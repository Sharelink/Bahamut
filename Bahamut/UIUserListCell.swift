//
//  UIUser.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework

class UIUserListCellBase: UITableViewCell
{
    private var avatarId:String!
    var rootController:LinkedUserListController!{
        didSet{
            if oldValue == nil{
                self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onCellTapped:"))
            }
        }
    }
    
    func updateAvatar(newAvatarId:String?, avatarImageView:UIImageView)
    {
        if String.isNullOrEmpty(avatarId) || avatarId != newAvatarId
        {
            avatarId = newAvatarId
            self.rootController.fileService.setAvatar(avatarImageView, iconFileId: avatarId)
        }
    }
    
    func onCellTapped(a:UITapGestureRecognizer)
    {
    }
}

//MARK: UIUserListMessageCell
class UIUserListMessageCell: UIUserListCellBase
{
    
    static let cellIdentifier:String = "UIUserListMessageCell"
    var model:LinkMessage!{
        didSet{
            update()
        }
    }
    
    
    @IBOutlet weak var noteNameLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!{
        didSet{
            avatar.layer.cornerRadius = 3.0
            avatar.userInteractionEnabled = true
            avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(self.avatar)
    }
    
    @IBAction func showDetail(sender: AnyObject)
    {
        self.rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.model.sharelinkerId)
    }
    
    override func onCellTapped(a:UITapGestureRecognizer)
    {
        self.rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.model.sharelinkerId)
    }
    
    private func update()
    {
        noteNameLabel.text = model.sharelinkerNick
        messageLabel.text = model.isAcceptAskLinkMessage() ? "USER_ACCEPT_YOUR_LINK".localizedString() : model.message
        self.updateAvatar(model.avatar, avatarImageView: avatar)
    }
}

//MARK: UIUserListAskingLinkCell
class UIUserListAskingLinkCell: UIUserListCellBase
{
    static let cellIdentifier:String = "UserAskLinkCell"
    var model:LinkMessage!{
        didSet{
            update()
        }
    }
    
    @IBOutlet weak var avatar: UIImageView!{
        didSet{
            avatar.layer.cornerRadius = 3.0
            avatar.userInteractionEnabled = true
            avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    
    @IBOutlet weak var userNickLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func onCellTapped(_:UIGestureRecognizer)
    {
        rootController.userService.showLinkConfirmViewController(self.rootController.navigationController!, linkMessage: self.model)
    }
    
    @IBAction func addButtonClicked(sender: AnyObject)
    {
        rootController.userService.showLinkConfirmViewController(self.rootController.navigationController!, linkMessage: self.model)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(self.avatar)
    }
    
    private func update()
    {
        userNickLabel.text = "\(model.sharelinkerNick)"
        messageLabel.text = String(format: "ASKING_FOR_A_LINK".localizedString(),model.sharelinkerNick!)
        updateAvatar(model.avatar, avatarImageView: avatar)
    }
    
}

//MARK: UIUserListCell
class UIUserListCell: UIUserListCellBase
{
    static let cellIdentifier:String = "UserCell"
    
    var userModel:Sharelinker!{
        didSet{
            update()
        }
    }
    
    @IBOutlet weak var levelLabel: UILabel!{
        didSet{
            //TODO: cancel hidden when level model completed
            levelLabel.hidden = true
            levelLabel.userInteractionEnabled = true
            levelLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showLevelRule:"))
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
        let title = "LEVEL_RULE_TITLE".localizedString()
        let msg = "LEVEL_RULE_DESC".localizedString()
        self.rootController.showAlert(title, msg: msg, actions: ALERT_ACTION_I_SEE)
    }
    
    override func onCellTapped(a: UITapGestureRecognizer) {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userProfile: self.userModel)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(self.avatarImageView)
    }
    
    func update()
    {
        userNickTextField.text = userModel.getNoteName()
        levelLabel.text = "Lv.\(userModel.level ?? 1)"
        self.updateAvatar(userModel.avatarId, avatarImageView: avatarImageView)
    }
}