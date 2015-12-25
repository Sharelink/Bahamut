//
//  UIShareMessage.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import ChatFramework

class UIShareMessage:UIShareCell
{
    static let RollMessageCellIdentifier = "RollMessage"
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var noteNameLabel: UILabel!{
        didSet{
            noteNameLabel.userInteractionEnabled = true
            noteNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showUserProfile:"))
            
        }
    }
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 3
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    @IBOutlet weak var messageLabel: UILabel!
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.shareModel.userId)
    }
    
    override func tapCell(_:UIGestureRecognizer)
    {
        if shareModel.isAddTagMessage() || shareModel.isFocusTagMessage()
        {
            let tag = SharelinkTheme(json: shareModel.shareContent)
            ServiceContainer.getService(SharelinkThemeService).showConfirmAddTagAlert(self.rootController, tag: tag)
        }
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
    override func update()
    {
        updateUserNoteName(self.noteNameLabel)
        updateAvatar(self.avatarImageView)
        updateTime(self.timeLabel)
        updateMessage()
    }
    
    private func updateName()
    {
        noteNameLabel.text = postUser?.getNoteName() ?? "Sharelinker"
    }
    
    private func updateMessage()
    {
        var format = ""
        var msgContent = ""
        if shareModel.isAddTagMessage()
        {
            format =  NSLocalizedString("ADD_THEME", comment: "")
        }else if shareModel.isFocusTagMessage()
        {
            format =  NSLocalizedString("FOCUS_ON", comment: "")
        }else if shareModel.isTextMessage()
        {
            format = "%@"
            msgContent = shareModel.message
        }
        else
        {
            format = NSLocalizedString("UNKNOW_SHARE_TYPE", comment: "")
        }
        if shareModel.isAddTagMessage() || shareModel.isFocusTagMessage()
        {
            msgContent = SharelinkTheme(json: shareModel.shareContent).getShowName()
        }
        messageLabel.text = String(format: format, msgContent)
    }
}

