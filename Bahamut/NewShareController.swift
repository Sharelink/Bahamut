//
//  NewShareController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import MJRefresh

//MARK: ShareService extension
extension ShareService
{
    func showNewShareController(currentNavigationController:UINavigationController,shareModel:ShareThing,isReshare:Bool)
    {
        let controller = NewShareController.instanceFromStoryBoard()
        controller.isReshare = isReshare
        let share = ShareThing()
        share.pShareId = shareModel.shareId
        share.shareId = shareModel.shareId
        share.shareContent = shareModel.shareContent
        share.shareType = shareModel.shareType
        share.forTags = shareModel.forTags
        share.message = shareModel.message
        controller.passedShareModel = share
        controller.hidesBottomBarWhenPushed = true
        currentNavigationController.pushViewController(controller, animated: true)
    }
}

//MARK: NewShareCellBase
class NewShareCellBase : UITableViewCell
{
    var fileService:FileService!{
        return rootController.fileService
    }
    
    var shareService:ShareService!{
        return rootController.shareService
    }
    
    var userService:UserService!{
        return rootController.userService
    }
    
    var isReshare:Bool{
        return rootController.isReshare
    }
    
    var rootView:UIView!{
        return rootController?.view
    }
    var rootController:NewShareController!
    func initCell()
    {
        
    }
    
    func clear()
    {
        
    }
}

//MARK: ShareContentCellBase
class ShareContentCellBase:NewShareCellBase
{
    func share(baseShareModel:ShareThing,themes:[SharelinkTheme]) -> Bool
    {
        return false
    }
    
    func getCellHeight()->CGFloat
    {
        return UITableViewAutomaticDimension
    }
}

//MARK:NewShareController
class NewShareController: UITableViewController
{
    var fileService:FileService!
    var shareService:ShareService!
    var userService:UserService!
    var srcService:SRCService!
    
    //views
    var titleView:NewControllerTitleView!
    
    //Reshare
    var isReshare:Bool = false
    var passedShareModel:ShareThing!
    
    var currentSRCPlugin:SRCPlugin!
    
    var shareMessageCell:NewShareMessageCell!
    var shareContentCell:ShareContentCellBase!
    var shareThemeCell:NewShareThemeCell!
    
    let shareMessageCellIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    let shareContentCellIndexPath = NSIndexPath(forRow: 1, inSection: 0)
    let shareThemeCellIndexPath = NSIndexPath(forRow: 2, inSection: 0)
    
    private var rowHights = [128,UITableViewAutomaticDimension,256]
    
    //MARK: SRCMenu
    @IBOutlet weak var srcMenuButtonItem: UIBarButtonItem!
    private var shareButtonItem:UIBarButtonItem!
    
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareService = ServiceContainer.getService(ShareService)
        self.fileService = ServiceContainer.getService(FileService)
        self.userService = ServiceContainer.getService(UserService)
        self.srcService = ServiceContainer.getService(SRCService)
        self.changeNavigationBarColor()
        self.initSRCPlugins()
        self.initTitleView()
        self.shareButtonItem = self.navigationItem.rightBarButtonItem
        self.initTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        MobClick.beginLogPageView("New")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("New")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit{
        if shareService != nil{
            shareService.removeObserver(self)
        }
    }
    
    //MARK: Init actions
    private func initTableView()
    {
        self.tableView.estimatedRowHeight = tableView.rowHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    private func initTitleView()
    {
        self.titleView = NewControllerTitleView.instanceFromXib()
        self.titleView.frame = CGRectMake(0, 0, 128, 32)
        self.shareService.addObserver(self, selector: "sharePosted:", name: ShareService.newSharePosted, object: nil)
        self.shareService.addObserver(self, selector: "sharePostFailed:", name: ShareService.newSharePostFailed, object: nil)
        self.shareService.addObserver(self, selector: "startPostingShare:", name: ShareService.startPostingShare, object: nil)
        self.navigationItem.titleView = self.titleView
    }
    
    //MARK: new share posted notification
    func sharePosted(a:NSNotification)
    {
        self.playCheckMark("POST_SHARE_SUC".localizedString())
        self.titleView.shareQueue--
    }
    
    func sharePostFailed(a:NSNotification)
    {
        self.playCrossMark("POST_SHARE_FAILED".localizedString())
        self.titleView.shareQueue--
    }
    
    func startPostingShare(a:NSNotification)
    {
        titleView.shareQueue++
        self.playCheckMark("SHARING".localizedString())
    }
    
    //MARK: clear view controller
    func clear()
    {
        shareMessageCell.clear()
        shareThemeCell.clear()
        shareContentCell.clear()
    }
    
    //MARK: share type
    private func initSRCPlugins(){
        let shareType = passedShareModel?.shareType ?? ShareThingType.shareFilm.rawValue
        self.currentSRCPlugin = srcService.getSRCPlugin(shareType)
    }
    
    private func refreshControllerTitle()
    {
        if let title = self.currentSRCPlugin.controllerTitle
        {
            self.titleView.titleLabel.text = title
        }else
        {
            self.titleView.titleLabel.text = NewControllerTitleView.defaultTitle
        }
    }
    
    func reloadContentCellHeight()
    {
        self.rowHights[shareContentCellIndexPath.row] = self.shareContentCell.getCellHeight()
    }
    
    func refreshContentCellHeight()
    {
        tableView.reloadData()
    }
    
    //MARK: post share
    @IBAction func share()
    {
        if self.shareThemeCell.selectedThemes.count == 0
        {
            SystemSoundHelper.vibrate()
            shareThemeCell.shakeAnimationForView()
            self.playToast("NO_SELECT_THEME_TIPS".localizedString())
        }else
        {
            self.isReshare ? self.reshare() : self.prepareShare()
        }
        MobClick.event("PostNew")
    }
    
    //MARK: reshare
    private func reshare()
    {
        let hud = self.showActivityHudWithMessage("",message: "SHARING".localizedString())
        self.shareService.reshare(self.passedShareModel.shareId, message: self.shareMessageCell.shareMessage, tags: self.shareThemeCell.selectedThemes){ isSuc,msg in
            hud.hideAsync(true)
            var alert:UIAlertController!
            if isSuc{
                alert = UIAlertController(title: "SHARE_SUCCESSED".localizedString(), message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel, handler: { (action) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }else
            {
                alert = UIAlertController(title: "SHARE_FAILED".localizedString(), message: msg, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel, handler: { (action) -> Void in
                    
                }))
            }
            self.showAlert(alert)
        }
    }
    
    //MARK: new share
    private func prepareShare()
    {
        let newShare = ShareThing()
        newShare.message = self.shareMessageCell.shareMessage
        let me = userService.myUserModel
        newShare.userId = me.userId
        newShare.userNick = me.nickName
        newShare.avatarId = me.avatarId
        newShare.shareTime = NSDate().toDateTimeString()
        let themes = self.shareThemeCell.selectedThemes
        newShare.reshareable = themes.contains{$0.isPrivateTheme()} ? "false" : "true"
        let canPost = shareContentCell.share(newShare,themes: themes)
        if canPost
        {
            if self.passedShareModel != nil{
                self.navigationController!.popViewControllerAnimated(true)
            }else
            {
                clear()
            }
        }else
        {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0), atScrollPosition: .None, animated: true)
            shareContentCell.shakeAnimationForView(7)
            SystemSoundHelper.vibrate()
        }
    }

    //MARK: table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHights[indexPath.row]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:NewShareCellBase!
        if indexPath.row == shareMessageCellIndexPath.row
        {
            self.shareMessageCell = tableView.dequeueReusableCellWithIdentifier(NewShareMessageCell.reuseableId,forIndexPath: indexPath) as! NewShareMessageCell
            cell = self.shareMessageCell
        }else if indexPath.row == shareContentCellIndexPath.row
        {
            self.shareContentCell = tableView.dequeueReusableCellWithIdentifier(currentSRCPlugin.srcCellId,forIndexPath: indexPath) as! ShareContentCellBase
            shareContentCell.rootController = self
            reloadContentCellHeight()
            refreshControllerTitle()
            cell = self.shareContentCell
        }else
        {
            self.shareThemeCell = tableView.dequeueReusableCellWithIdentifier(NewShareThemeCell.reuseableId,forIndexPath: indexPath) as! NewShareThemeCell
            cell = self.shareThemeCell
        }
        cell.rootController = self
        cell.initCell()
        return cell
    }
    
    //MARK: instance from storyboard
    static func instanceFromStoryBoard() -> NewShareController
    {
        return instanceFromStoryBoard("SharelinkMain", identifier: "NewShareController",bundle: Sharelink.mainBundle()) as! NewShareController
    }
}