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
    @IBOutlet weak var messageLabel: UILabel!{
        didSet{
            messageLabel.userInteractionEnabled = true
            messageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showMessageAlert:"))
        }
    }
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
    
    func showMessageAlert(_:UIGestureRecognizer)
    {
        let alert = UIAlertController(title: noteNameLabel.text, message: self.messageLabel.text, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: nil))
        self.rootController.presentViewController(alert, animated: true, completion: nil)
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
        }else if (shareThingModel.isFocusTagMessage())
        {
            format =  NSLocalizedString("FOCUS_ON", comment: "")
        }else
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

class UIShareThing: UITableViewCell,UIShareContentViewSetupDelegate
{
    static let ShareThingCellIdentifier = "ShareThing"
    struct Constants
    {
        static let VotePrefixEmoji = "💙"

    }
    
    var rootController:ShareThingsListController!
    var user:Sharelinker!
    var shareThingModel:ShareThing!
    {
        didSet
        {
            user = rootController.userService.getUser(shareThingModel.userId)
            shareContent.delegate = UIShareContentTypeDelegateGenerator.getDelegate(shareThingModel.shareType)
            shareContent.share = shareThingModel
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    deinit
    {
    }
    @IBOutlet weak var sendingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var themeLabel: UILabel!
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
            shareContent.setupContentViewDelegate = self
            var gesture = UISwipeGestureRecognizer(target: self, action: "swipeShareThingLeft:")
            gesture.direction = UISwipeGestureRecognizerDirection.Left
            self.addGestureRecognizer(gesture)
            gesture = UISwipeGestureRecognizer(target: self, action: "swipeShareThingRight:")
            gesture.direction = UISwipeGestureRecognizerDirection.Right
            self.addGestureRecognizer(gesture)
        }
    }
    
    func setupContentView(contentView: UIView, share: ShareThing) {
        if share.isShareFilm()
        {
            if let player = contentView as? ShareLinkFilmView
            {
                player.autoLoad = false
                player.autoPlay = true
                player.playerController.fillMode = AVLayerVideoGravityResizeAspect
                player.fileFetcher = rootController.fileService.getFileFetcherOfFileId(.Video)
            }
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
        if shareThingModel.canReshare()
        {
            rootController.shareService.showReshareViewController(self.rootController.navigationController!, reShareModel: shareThingModel)
        }else
        {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("RESHARELESS_TIPS", comment: "This Share Is Not Allow Reshare!"), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE",comment:""), style: UIAlertActionStyle.Cancel ,handler:nil))
            rootController.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    private func cancelShare()
    {
        
    }
    
    @IBAction func reply()
    {
        let controller = ChatViewController.instanceFromStoryBoard()
        controller.shareChat = rootController.messageService.getShareChatHub(shareThingModel.shareId,shareSenderId: shareThingModel.userId)
        self.rootController.navigationController?.pushViewController(controller, animated: true)
        self.replyButton.badgeValue = nil
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
        if user == nil
        {
            user = rootController.userService.getUser(shareThingModel.userId)
        }
        if user == nil
        {
            return
        }
        shareDesc.text = shareThingModel.message
        shareDateTime.text = shareThingModel.shareTimeOfDate.toFriendlyString()
        updateBadge()
        updateVote()
        updateContent()
        updateAvatar()
        updateUserNick()
        updateSending()
        updateTheme()
    }
    
    private func updateTheme()
    {
        if let firstTheme = shareThingModel?.forTags.first
        {
            let stm = SendTagModel(json: firstTheme)
            let tag = SharelinkTag()
            tag.tagName = stm.name
            tag.type = stm.type
            tag.data = stm.data
            themeLabel.text = tag.getShowName()
        }else
        {
            themeLabel.text = ""
        }
    }
    
    private func updateSending()
    {
        if rootController.shareService.sendingShareId.keys.contains(self.shareThingModel.shareId)
        {
            self.sendingIndicator.hidden = false
            self.sendingIndicator.startAnimating()
        }else
        {
            self.sendingIndicator.hidden = true
        }
    }
    
    private func updateBadge()
    {
        let notReadmsg = rootController.messageService.getShareNewMessageCount(shareThingModel.shareId)
        replyButton.badgeValue = "\(notReadmsg)"
    }
    
    var voted:Bool
    {
        let myUserId = rootController.userService.myUserId
        if shareThingModel.voteUsers == nil
        {
            return false
        }
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
        shareContent.update()
    }
    
    private func updateUserNick()
    {
        userNicknameLabel.text = user.getNoteName()
    }
    
    private func updateAvatar()
    {
        rootController.fileService.setAvatar(self.avatarImageView, iconFileId: user?.avatarId ?? shareThingModel.avatarId)
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
}
