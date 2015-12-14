//
//  ShareThing.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import ChatFramework

class UIShareThing: UIShareCell,UIShareContentViewSetupDelegate
{
    static let ShareThingCellIdentifier = "ShareThing"
    struct Constants
    {
        static let VotePrefixEmoji = "💙"

    }

    override var shareModel:ShareThing!
    {
        didSet
        {
            postUser = rootController.userService.getUser(shareModel.userId)
            shareContent.delegate = UIShareContentTypeDelegateGenerator.getDelegate(shareModel.shareType)
            shareContent.share = shareModel
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
    @IBOutlet weak var sendingIndicator: UIActivityIndicatorView!{
        didSet{
            sendingIndicator.stopAnimating()
            sendingIndicator.hidden = true
        }
    }
    
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!{
        didSet{
            avatarImageView.layer.cornerRadius = 7
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
                ServiceContainer.getService(ShareService).unVoteShareThing(self.shareModel,updateCallback: self.updateVote)
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL",comment:""), style: UIAlertActionStyle.Cancel){ _ in })
            rootController.presentViewController(alert, animated: true, completion: nil)
        }else{
            
            ServiceContainer.getService(ShareService).voteShareThing(shareModel,updateCallback: updateVote)
            MobClick.event("Vote")
        }
    }
    
    @IBAction func shareToFriends()
    {
        if shareModel.canReshare()
        {
            MobClick.event("Reshare")
            rootController.shareService.showReshareController(self.rootController.navigationController!, reShareModel: shareModel)
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
        controller.shareChat = rootController.messageService.getShareChatHub(shareModel.shareId,shareSenderId: shareModel.userId)
        let navController = UINavigationController(rootViewController: controller)
        controller.changeNavigationBarColor()
        self.replyButton.badgeValue = nil
        MainViewTabBarController.currentTabBarViewController.reduceTabItemBadge(MainViewTabBarController.ShareTabItemBadgeIndex, badgeReduce: notReadmsg)
        self.rootController.presentViewController(navController, animated: true) { () -> Void in
            
        }
        
    }
    
    func showUserProfile(_:UIGestureRecognizer)
    {
        rootController.userService.showUserProfileViewController(self.rootController.navigationController!, userId: self.shareModel.userId)
    }

    override func layoutSubviews() {
        updateBadge()
        super.layoutSubviews()
    }
    
    override func update()
    {
        shareDesc.text = shareModel.message
        updateBadge()
        updateVote()
        updateSending()
        updateTheme()
        updateAvatar(self.avatarImageView)
        updateUserNoteName(self.userNicknameLabel)
        updateTime(self.shareDateTime)
        updateContent()
        self.layoutIfNeeded()
    }
    
    private func updateTheme()
    {
        if let firstTheme = shareModel?.forTags?.first
        {
            let stm = SendTagModel(json: firstTheme)
            let tag = SharelinkTheme()
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
        if rootController.shareService.sendingShareId.keys.contains(self.shareModel.shareId)
        {
            self.sendingIndicator.hidden = false
            self.sendingIndicator.startAnimating()
        }else
        {
            self.sendingIndicator.hidden = true
            self.sendingIndicator.stopAnimating()
        }
    }
    
    var notReadmsg = 0
    private func updateBadge()
    {
        notReadmsg = rootController.messageService.getShareNewMessageCount(shareModel.shareId)
        replyButton.badgeValue = "\(notReadmsg)"
    }
    
    var voted:Bool
    {
        let myUserId = rootController.userService.myUserId
        if shareModel.voteUsers == nil
        {
            return false
        }
        return self.shareModel.voteUsers.contains{$0 == myUserId}
    }
    
    private func updateVote()
    {
        voteButton.tintColor = voted ?  UIShareThing.voteButtonVotedColor : UIShareThing.voteOriginColor
        var voteString = ""
        if let users = shareModel.voteUsers
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
    
    func updateContent()
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.shareContent.update()
        }
    }
    
    func showAvatar(_:UIGestureRecognizer)
    {
        UUImageAvatarBrowser.showImage(avatarImageView)
    }
    
}
