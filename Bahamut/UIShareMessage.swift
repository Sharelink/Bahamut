//
//  UIShareMessage.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class UIShareMessage:UIShareCell
{
    static let RollMessageCellIdentifier = "RollMessage"
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var noteNameLabel: UILabel!{
        didSet{
            noteNameLabel.userInteractionEnabled = true
            noteNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UIShareMessage.showUserProfile(_:))))
            
        }
    }
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 7
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UIShareMessage.showAvatar(_:))))
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
            let theme = SharelinkTheme(json: shareModel.shareContent)
            ServiceContainer.getService(SharelinkThemeService).showConfirmAddThemeAlert(self.rootController, theme: theme)
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
            format =  "ADD_THEME".localizedString()
        }else if shareModel.isFocusTagMessage()
        {
            format =  "FOCUS_ON".localizedString()
        }else if shareModel.isTextMessage()
        {
            format = "%@"
            msgContent = shareModel.message
        }
        else
        {
            format = "UNKNOW_SHARE_TYPE".localizedString()
        }
        if shareModel.isAddTagMessage() || shareModel.isFocusTagMessage()
        {
            msgContent = SharelinkTheme(json: shareModel.shareContent).getShowName()
        }
        messageLabel.text = String(format: format, msgContent)
    }
}

