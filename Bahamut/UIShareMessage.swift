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

class UIShareMessage:UITableViewCell
{
    static let dateFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        formatter.timeZone = NSTimeZone()
        return formatter
    }()
    static let RollMessageCellIdentifier = "RollMessage"
    var user:Sharelinker!
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
    
    var rootController:ShareThingsListController!{
        didSet{
            self.userInteractionEnabled = true
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCell:"))
        }
    }
    var shareThingModel:ShareThing!{
        didSet
        {
            user = rootController.userService.getUser(shareThingModel.userId)
            update()
        }
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.shareThingModel.userId)
    }
    
    func tapCell(_:UIGestureRecognizer)
    {
        if shareThingModel.isAddTagMessage() || shareThingModel.isFocusTagMessage()
        {
            let tag = SharelinkTag(json: shareThingModel.shareContent)
            ServiceContainer.getService(SharelinkTagService).showConfirmAddTagAlert(self.rootController, tag: tag)
        }
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
    func update()
    {
        updateName()
        updateTime()
        updateAvatar()
        updateMessage()
    }
    
    private func updateAvatar()
    {
        rootController.fileService.setAvatar(avatarImageView, iconFileId: user?.avatarId ?? shareThingModel.avatarId)
    }
    
    private func updateTime()
    {
        timeLabel.text = shareThingModel.shareTimeOfDate.toFriendlyString(UIShareMessage.dateFomatter)
    }
    
    private func updateName()
    {
        noteNameLabel.text = user.getNoteName()
    }
    
    private func updateMessage()
    {
        var format = ""
        var msgContent = ""
        if shareThingModel.isAddTagMessage()
        {
            format =  NSLocalizedString("ADD_TAG", comment: "")
        }else if shareThingModel.isFocusTagMessage()
        {
            format =  NSLocalizedString("FOCUS_ON", comment: "")
        }else if shareThingModel.isTextMessage()
        {
            format = "%@"
            msgContent = shareThingModel.message
        }
        else
        {
            format = NSLocalizedString("UNKNOW_SHARE_TYPE", comment: "")
        }
        if shareThingModel.isAddTagMessage() || shareThingModel.isFocusTagMessage()
        {
            msgContent = SharelinkTag(json: shareThingModel.shareContent).getShowName()
        }
        messageLabel.text = String(format: format, msgContent)
    }
}

