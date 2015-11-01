//
//  ShareThing.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework
import SharelinkSDK

class UIShareMessage:UITableViewCell
{
    static let dateFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        formatter.timeZone = NSTimeZone()
        return formatter
    }()
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
    @IBOutlet weak var messageLabel: UILabel!{
        didSet{
            
        }
    }
    var rootController:ShareThingsListController!{
        didSet{
            self.userInteractionEnabled = true
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCell:"))
        }
    }
    var shareThingModel:ShareThing!
        {
        didSet
        {
            update()
        }
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.shareThingModel.userId)
    }
    
    func tapCell(_:UIGestureRecognizer)
    {
        
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
    private func update()
    {
        let sender = rootController.userService.getUser(shareThingModel.userId)
        let noteName = sender?.noteName ?? sender?.nickName ?? ""
        timeLabel.text = shareThingModel.shareTimeOfDate.toFriendlyString(UIShareMessage.dateFomatter)
        noteNameLabel.text = sender?.noteName ?? shareThingModel.userNick
        avatarImageView.image = PersistentManager.sharedInstance.getImage(sender?.avatarId ?? shareThingModel.avatarId) ??
            PersistentManager.sharedInstance.getImage(ImageAssetsConstants.defaultAvatar)
        messageLabel.text = noteName + " \(NSLocalizedString("FOCUS_ON", comment: "")) \(shareThingModel.shareContent)"
    }
}

class UIShareThing: UITableViewCell
{
    static let ShareThingCellIdentifier = "ShareThing"
    struct Constants
    {
        static let VotePrefixEmoji = "👍"

    }
    
    var rootController:ShareThingsListController!
    
    var shareThingModel:ShareThing!
    {
        didSet
        {
            update()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 3
            avatarImageView.userInteractionEnabled = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showAvatar:"))
        }
    }
    @IBOutlet weak var userNicknameLabel: UILabel!{
        didSet{
            userNicknameLabel.userInteractionEnabled = true
            userNicknameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showUserProfile:"))
        }
    }
    @IBOutlet weak var shareButton: UIButton!{
        didSet{
            shareButton.tintColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var shareDateTime: UILabel!
    @IBOutlet weak var shareContent: UIShareContent!{
        didSet{
            var gesture = UISwipeGestureRecognizer(target: self, action: "swipeShareThingLeft:")
            gesture.direction = UISwipeGestureRecognizerDirection.Left
            self.addGestureRecognizer(gesture)
            gesture = UISwipeGestureRecognizer(target: self, action: "swipeShareThingRight:")
            gesture.direction = UISwipeGestureRecognizerDirection.Right
            self.addGestureRecognizer(gesture)
        }
    }
    
    @IBOutlet weak var userVoteDetail: UILabel!{
        didSet{
            userVoteDetail.textColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var replyButton: UIButton!{
        didSet{
            replyButton.tintColor = UIColor.themeColor
        }
    }
    @IBOutlet weak var shareDesc: UILabel!
    
    func swipeShareThingRight(gesture:UISwipeGestureRecognizer)
    {
        NSLog("swipe right")
    }
    
    func swipeShareThingLeft(gesture:UISwipeGestureRecognizer)
    {
        NSLog("swipe left")
    }
    
    private static var voteOriginColor:UIColor!
    private static var voteButtonVotedColor:UIColor!
    @IBOutlet weak var voteButton: UIButton!{
        didSet{
            if UIShareThing.voteOriginColor == nil{
                UIShareThing.voteOriginColor = voteButton.tintColor
                UIShareThing.voteButtonVotedColor = UIColor.themeColor
            }
        }
    }
    
    @IBAction func vote()
    {
        if voted
        {
            let alert = UIAlertController(title: NSLocalizedString("UNVOTE_SHARE_CONFIRM", comment: ""), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: UIAlertActionStyle.Default){ aa in
                ServiceContainer.getService(ShareService).unVoteShareThing(self.shareThingModel,updateCallback: self.updateVote)
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL",comment:""), style: UIAlertActionStyle.Cancel){ _ in })
            rootController.presentViewController(alert, animated: true, completion: nil)
        }else{
            
            ServiceContainer.getService(ShareService).voteShareThing(shareThingModel,updateCallback: updateVote)
        }
    }
    
    @IBAction func shareToFriends()
    {
        let alert = UIAlertController(title: NSLocalizedString("RESHARE_CONFIRM", comment: ""), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("SHARE",comment:""), style: UIAlertActionStyle.Default){ aa in
            let textField = alert.textFields?.first
            self.reshare(textField?.text ?? nil)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL",comment:""), style: UIAlertActionStyle.Cancel){ _ in self.cancelShare()})
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Say something to your linkers"
        }
        rootController.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func cancelShare()
    {
        
    }
    
    private func reshare(message:String! = nil)
    {
        let shareService = ServiceContainer.getService(ShareService)
        shareService.reshare(self.shareThingModel.shareId, message: message)
    }
    
    @IBAction func reply()
    {
        let controller = ChatViewController.instanceFromStoryBoard()
        controller.shareChat = rootController.messageService.getShareChatHub(shareThingModel.shareId,shareSenderId: shareThingModel.userId)
        self.rootController.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.shareThingModel.userId)
    }

    override func layoutSubviews() {
        updateBadge()
        super.layoutSubviews()
    }
    
    func update()
    {
        shareDesc.text = shareThingModel.title
        shareDateTime.text = shareThingModel.shareTimeOfDate.toFriendlyString()
        updateBadge()
        updateVote()
        updateContent()
        updateAvatar()
        updateUserNick()
    }
    
    private func updateBadge()
    {
        let notReadmsg = rootController.messageService.getShareNewMessageCount(shareThingModel.shareId)
        replyButton.badgeValue = "\(notReadmsg)"
    }
    
    var voted:Bool
    {
        let myUserId = rootController.userService.myUserId
        return self.shareThingModel.voteUsers.contains{$0 == myUserId}
    }
    
    private func updateVote()
    {
        voteButton.tintColor = voted ?  UIShareThing.voteButtonVotedColor : UIShareThing.voteOriginColor
        var voteString = ""
        if let users = shareThingModel.voteUsers
        { 
            let userNicks = users.map{rootController.userService.getUserNoteName($0)}.filter{String.isNullOrWhiteSpace($0) == false }
            voteString =  userNicks.joinWithSeparator(",")
        }
        if String.isNullOrWhiteSpace(voteString)
        {
            userVoteDetail.hidden = true
        }else
        {
            userVoteDetail.hidden = false
            userVoteDetail.text = "\(Constants.VotePrefixEmoji)\(voteString)"
        }
    }
    
    private func updateContent()
    {
        if shareContent.delegate == nil
        {
            shareContent.delegate = UIShareContentTypeDelegateGenerator.getDelegate(shareThingModel.shareType)
        }
        shareContent.shareThing = shareThingModel
    }
    
    private func updateUserNick()
    {
        userNicknameLabel.text = rootController.userService.getUserNoteName(shareThingModel.userId) ?? (shareThingModel.userNick ?? "Sharelinker")
    }
    
    private func updateAvatar()
    {
        rootController.fileService.setAvatar(self.avatarImageView, iconFileId: rootController.userService.getUser(shareThingModel.userId)?.avatarId)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
}
