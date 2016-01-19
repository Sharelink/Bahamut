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
    var srcService:SRCService!
    
    //views
    var titleView:NewControllerTitleView!
    
    //Reshare
    var isReshare:Bool = false
    var reShareModel:ShareThing!
    
    //New Share
    var defaultSRCIndex:Int = 0{
        didSet{
            if srcService != nil && self.defaultSRCIndex < srcService.defaultSRCPlugins.count
            {
                self.currentSRCPlugin = srcService.defaultSRCPlugins[self.defaultSRCIndex]
            }
        }
    }
    var currentSRCPlugin:SRCPlugin!
    
    private var userGuide:UserGuide!
    
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
    private var srcMenu:UIView!
    private var srcMenuFrame:CGRect!
    private var srcMenuBackLayer:UIView!
    
    //MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareService = ServiceContainer.getService(ShareService)
        self.fileService = ServiceContainer.getService(FileService)
        self.userService = ServiceContainer.getService(UserService)
        self.srcService = ServiceContainer.getService(SRCService)
        self.changeNavigationBarColor()
        self.initUserGuide()
        self.initShareType()
        self.initTitleView()
        self.initSRCMenu()
        self.shareButtonItem = self.navigationItem.rightBarButtonItem
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
        if UserSetting.isAppstoreReviewing == false
        {
            userGuide.showGuideControllerPresentFirstTime()
        }
    }
    
    deinit{
        if shareService != nil{
            shareService.removeObserver(self)
        }
    }
    
    //Init
    private func initTitleView()
    {
        self.titleView = NewControllerTitleView.instanceFromXib()
        self.titleView.frame = CGRectMake(0, 0, 128, 32)
        self.shareService.addObserver(self, selector: "sharePosted:", name: ShareService.newSharePosted, object: nil)
        self.navigationItem.titleView = self.titleView
    }
    
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(SharelinkSetting.lang, viewName: "New")
        self.userGuide.initGuide(self, userId: UserSetting.userId, guideImgs: guideImgs)
    }
    
    private func initSRCMenu()
    {
        self.srcMenuBackLayer = UIView(frame: self.view.bounds)
        self.srcMenuBackLayer.userInteractionEnabled = true
        self.srcMenuBackLayer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        self.srcMenuBackLayer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "hideSRCMenu:"))
        self.srcMenu = UIView(frame: CGRectZero)
        self.srcMenu.layer.cornerRadius = 7
        self.srcMenu.backgroundColor = UIColor.themeColor.colorWithAlphaComponent(0.7)
        self.srcMenu.hidden = true
        self.srcMenuFrame = CGRectMake(0, -7, self.view.frame.width, self.view.frame.height / 2)
        self.view.addSubview(srcMenu)
    }
    
    //MARK: new share posted notification
    func sharePosted(a:NSNotification)
    {
        self.titleView.shareQueue--
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
            self.currentSRCPlugin = srcService.getSRCPlugin(reShareModel.shareType)
            self.navigationItem.leftBarButtonItems?.removeAll()
        }else
        {
            self.defaultSRCIndex = UserSetting.isAppstoreReviewing ? 1 : 0
            let header = MJRefreshGifHeader(){
                self.selectShareType(self.nextDefaultPluginIndex)
                self.tableView.mj_header.endRefreshing()
            }
            self.tableView.mj_header = header
            header.lastUpdatedTimeLabel?.hidden = true
            refreshHeaderTitle()
        }
    }
    
    private func refreshHeaderTitle()
    {
        let nextSRCPlugin = srcService.defaultSRCPlugins[self.nextDefaultPluginIndex]
        let header = self.tableView.mj_header as! MJRefreshGifHeader
        let format = "NEW_SHARE_PULL_SWITCH_TO".localizedString
        let headerTitle = NSLocalizedString(nextSRCPlugin.srcHeaderTitle, comment: "")
        let msg = String(format: format, headerTitle)
        header.setTitle(msg, forState: .Idle)
        header.setTitle(msg, forState: .Pulling)
        header.setTitle(msg, forState: .Refreshing)
        let headerImage = nextSRCPlugin.srcHeaderIcon
        header.setImages([headerImage], forState: .Idle)
    }
    
    private var nextDefaultPluginIndex:Int{
        let index = (self.defaultSRCIndex + 1) % srcService.defaultSRCPlugins.count
        return index
    }
    
    private func selectShareType(index:Int)
    {
        self.defaultSRCIndex = index
        refreshHeaderTitle()
        tableView.reloadData()
    }
    
    func reloadContentCellHeight()
    {
        self.rowHights[shareContentCellIndexPath.row] = self.shareContentCell.getCellHeight()
    }
    
    func refreshContentCellHeight()
    {
        tableView.reloadData()
    }
    
    //MARK: select share rich content
    
    @IBAction func SRCMenuCliecked(sender: AnyObject)
    {
        self.srcMenu.hidden ? showSRCMenu() : hideSRCMenu()
    }
    
    private func showSRCMenu()
    {
        self.view.addSubview(self.srcMenuBackLayer)
        self.view.bringSubviewToFront(self.srcMenu)
        self.tableView.scrollEnabled = false
        UIView.beginAnimations("animationID", context: nil)
        self.titleView.titleLabel.hidden = true
        self.srcMenu.hidden = false
        self.srcMenu.frame = self.srcMenuFrame
        self.srcMenuButtonItem.tintColor = UIColor.orangeColor()
        self.navigationItem.rightBarButtonItems = nil
        self.tabBarController!.tabBar.hidden = true
        UIView.commitAnimations()
    }
    
    func hideSRCMenu(_:UITapGestureRecognizer)
    {
        hideSRCMenu()
    }
    
    private func hideSRCMenu()
    {
        UIView.beginAnimations("animationID", context: nil)
        self.srcMenu.hidden = true
        self.srcMenu.frame = CGRectZero
        self.srcMenuButtonItem.tintColor = UIColor.whiteColor()
        UIView.commitAnimations()
        self.titleView.titleLabel.hidden = false
        self.srcMenuBackLayer.removeFromSuperview()
        self.tableView.scrollEnabled = true
        self.navigationItem.rightBarButtonItems = [self.shareButtonItem]
        self.tabBarController!.tabBar.hidden = false
    }
    
    //MARK: post share
    @IBAction func share()
    {
        if self.shareThemeCell.selectedThemes.count == 0
        {
            let alert = UIAlertController(title: "NO_SELECT_THEME_ALERT_TITLE".localizedString, message: "NO_SELECT_THEME_TIPS".localizedString, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "CONTINUE".localizedString, style: UIAlertActionStyle.Default, handler: { (ac) -> Void in
                self.isReshare ? self.reshare() : self.prepareShare()
            }))
            alert.addAction(UIAlertAction(title: "CANCEL".localizedString, style: UIAlertActionStyle.Cancel, handler: nil))
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
        self.makeToastActivityWithMessage("",message: "SHARING".localizedString)
        self.shareService.reshare(self.reShareModel.shareId, message: self.shareMessageCell.shareMessage, tags: self.shareThemeCell.selectedThemes){ isSuc,msg in
            self.hideToastActivity()
            var alert:UIAlertController!
            if isSuc{
                alert = UIAlertController(title: "SHARE_SUCCESSED".localizedString, message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE".localizedString, style: .Cancel, handler: { (action) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }else
            {
                alert = UIAlertController(title: "SHARE_FAILED".localizedString, message: msg, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE".localizedString, style: .Cancel, handler: { (action) -> Void in
                    
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
            titleView.shareQueue++
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
            self.shareContentCell = tableView.dequeueReusableCellWithIdentifier(currentSRCPlugin.srcCellId,forIndexPath: indexPath) as! ShareContentCellBase
            shareContentCell.rootController = self
            reloadContentCellHeight()
            if let title = self.currentSRCPlugin.controllerTitle
            {
                self.titleView.titleLabel.text = title
            }else
            {
                self.titleView.titleLabel.text = NewControllerTitleView.defaultTitle
            }
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