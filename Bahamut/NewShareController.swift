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
    func showReshareController(currentNavigationController:UINavigationController,reShareModel:ShareThing)
    {
        let controller = NewShareController.instanceFromStoryBoard()
        controller.isReshare = true
        let reshare = ShareThing()
        reshare.pShareId = reShareModel.shareId
        reshare.shareId = reShareModel.shareId
        reshare.shareContent = reShareModel.shareContent
        reshare.shareType = reShareModel.shareType
        reshare.forTags = reShareModel.forTags
        reshare.message = reShareModel.message
        controller.reShareModel = reshare
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
    
    //Reshare
    var isReshare:Bool = false
    var reShareModel:ShareThing!
    
    //New Share
    var shareCellReuseIdIndex:Int = 0
    
    private var userGuide:UserGuide!
    
    var shareMessageCell:NewShareMessageCell!
    var shareContentCell:ShareContentCellBase!
    var shareThemeCell:NewShareThemeCell!
    
    let shareMessageCellIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    let shareContentCellIndexPath = NSIndexPath(forRow: 1, inSection: 0)
    let shareThemeCellIndexPath = NSIndexPath(forRow: 2, inSection: 0)
    
    private var rowHights = [128,UITableViewAutomaticDimension,256]
    
    //MARK: life process
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUserGuide()
        self.shareService = ServiceContainer.getService(ShareService)
        self.fileService = ServiceContainer.getService(FileService)
        self.userService = ServiceContainer.getService(UserService)
        self.changeNavigationBarColor()
        self.initShareType()
        self.tableView.estimatedRowHeight = tableView.rowHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.dataSource = self
        self.tableView.reloadData()
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
        self.userGuide.showGuideControllerPresentFirstTime()
    }
    
    //Init
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(SharelinkSetting.lang, viewName: "New")
        self.userGuide.initGuide(self, userId: SharelinkSetting.userId, guideImgs: guideImgs)
    }
    
    //MARK: clear view controller
    func clear()
    {
        shareMessageCell.clear()
        shareThemeCell.clear()
        shareContentCell.clear()
    }
    
    //MARK: share type
    private func initShareType(){
        if isReshare
        {
            self.shareCellReuseIdIndex = NewShareCellConfig.indexOfShareType(ShareThingType(rawValue: reShareModel.shareType)!) ?? 0
        }else
        {
            self.shareCellReuseIdIndex = 0
            let header = MJRefreshGifHeader(){
                self.nextShareType()
                self.tableView.mj_header.endRefreshing()
            }
            self.tableView.mj_header = header
            header.lastUpdatedTimeLabel?.hidden = true
            refreshHeaderTitle()
        }
    }
    
    private func refreshHeaderTitle()
    {
        let cellConfig = NewShareCellConfig.CellConfig[self.nextShareTypeIndex()]
        let header = self.tableView.mj_header as! MJRefreshGifHeader
        let format = NSLocalizedString("NEW_SHARE_PULL_SWITCH_TO", comment: "")
        let headerTitle = NSLocalizedString(cellConfig.headerTitleLocalizedKey, comment: "")
        let msg = String(format: format, headerTitle)
        header.setTitle(msg, forState: .Idle)
        header.setTitle(msg, forState: .Pulling)
        header.setTitle(msg, forState: .Refreshing)
        if let shareName = cellConfig.shareType.getShareTypeName()
        {
            let image = UIImage(named: "new_share_header_icon_\(shareName)")!
            header.setImages([image], forState: .Idle)
        }
    }
    
    private func nextShareTypeIndex() -> Int{
        let index = (self.shareCellReuseIdIndex + 1) % NewShareCellConfig.numberOfNewShareCellType
        return index
    }
    
    private func nextShareType()
    {
        let index = nextShareTypeIndex()
        selectShareType(index)
    }
    
    func selectShareType(index:Int)
    {
        if index >= 0 && index < NewShareCellConfig.numberOfNewShareCellType
        {
            self.shareCellReuseIdIndex = index
            refreshHeaderTitle()
            tableView.reloadData()
        }
    }
    
    func selectShareTypeByCellReuseId(typeCellReuseId:String)
    {
        if let index = NewShareCellConfig.indexOfReuseId(typeCellReuseId)
        {
            selectShareType(index)
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
            let alert = UIAlertController(title: NSLocalizedString("SHARE", comment:  ""), message: NSLocalizedString("NO_SELECT_TAG_TIPS", comment:  ""),preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment:  ""), style: UIAlertActionStyle.Default, handler: { (ac) -> Void in
                self.isReshare ? self.reshare() : self.prepareShare()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment:  ""), style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil )
        }else
        {
            self.isReshare ? self.reshare() : self.prepareShare()
        }
        MobClick.event("PostNew")
    }
    
    //MARK: reshare
    private func reshare()
    {
        self.makeToastActivityWithMessage("",message: NSLocalizedString("SHARING", comment: "Sharing"))
        self.shareService.reshare(self.reShareModel.shareId, message: self.shareMessageCell.shareMessage, tags: self.shareThemeCell.selectedThemes){ isSuc,msg in
            self.hideToastActivity()
            var alert:UIAlertController!
            if isSuc{
                alert = UIAlertController(title: NSLocalizedString("SHARE_SUCCESSED", comment: "Share Successed"), message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }else
            {
                alert = UIAlertController(title: NSLocalizedString("SHARE_FAILED", comment: "Share Failed"), message: msg, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    
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
            clear()
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
            self.shareContentCell = tableView.dequeueReusableCellWithIdentifier(NewShareCellConfig.CellConfig[self.shareCellReuseIdIndex].cellReuseId,forIndexPath: indexPath) as! ShareContentCellBase
            shareContentCell.rootController = self
            reloadContentCellHeight()
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
        return instanceFromStoryBoard("Main", identifier: "NewShareController") as! NewShareController
    }
}