//
//  ThemeListViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/24.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
let ThemeHeaderSystem = NSLocalizedString("THEME_HEADER_SYSTEM", comment:"Sharelink")
let ThemeHeaderCustom = NSLocalizedString("THEME_HEADER_CUSTOM", comment:"Cutstom")
//MARK: extension SharelinkTheme
extension SharelinkTheme
{
    func getThemeIcon() -> UIImage
    {
        let themeType = self.type.stringByReplacingOccurrencesOfString(":", withString: "")
        return UIImage(named: "theme_icon_\(themeType).png") ?? UIImage(named: "theme_icon_keyword.png")!
    }
}

//MARK: ThemeCell
class ThemeCell: UITableViewCell,EditThemeViewControllerDelegate
{
    static let reuseId = "ThemeCell"
    var theme:SharelinkTheme!
    var rootController:ThemeListViewController!
    @IBOutlet weak var themeColorView: UIView!{
        didSet{
            themeColorView.layer.cornerRadius = 7
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "modifyTheme:"))
        }
    }
    static let privateImageIcon = UIImage(named: "private")!
    static let focusImageIcon = UIImage(named: "heart")!
    private var markImages:[UIImageView?] = [nil,nil,nil]
    @IBOutlet weak var themeNameLabel: UILabel!
    @IBOutlet weak var markImage0: UIImageView!{
        didSet{
            markImages[0] = markImage0
        }
    }
    @IBOutlet weak var markImage1: UIImageView!{
        didSet{
            markImages[1] = markImage1
        }
    }
    @IBOutlet weak var markImage2: UIImageView!{
        didSet{
            markImages[2] = markImage2
        }
    }
    
    func modifyTheme(_:UITapGestureRecognizer)
    {
        if theme.isSystemTheme() || theme.isSharelinkerTheme()
        {
            if theme.isSystemTheme()
            {
                rootController.showToast(NSLocalizedString("A_DEFAULT_THEME", comment: ""))
            }else
            {
                rootController.showToast(NSLocalizedString("A_SHARELINKER_THEME", comment: ""))
            }
            return
        }
        ServiceContainer.getService(UserService).showUserThemeEditController(rootController.navigationController!, editModel: theme,editMode:.Edit, delegate: self)
    }
    
    func editThemeViewControllerSave(saveModel: SharelinkTheme, sender: EditThemeViewController) {
        rootController.themeService.updateTheme(saveModel){suc in
            var msg = ""
            if suc
            {
                self.theme = saveModel
                self.refreshUI()
                msg = NSLocalizedString("MODIFY_THEME_SUC", comment: "")
            }else
            {
                msg = NSLocalizedString("MODIFY_THEME_ERROR", comment: "")
            }
            self.rootController.showToast(msg)
        }
    }
    
    func refreshUI()
    {
        var markImgs = [UIImage]()
        themeColorView.backgroundColor = UIColor(hexString: theme.tagColor)
        themeNameLabel.text = theme.getShowName(false)
        markImgs.append(theme.getThemeIcon())
        
        if "true" == theme.isFocus
        {
            markImgs.append(ThemeCell.focusImageIcon)
        }
        
        if "false" == theme.showToLinkers
        {
            markImgs.append(ThemeCell.privateImageIcon)
        }
        
        for i in 0..<markImages.count
        {
            if i < markImgs.count
            {
                markImages[i]?.image = markImgs[i]
                markImages[i]?.hidden = false
            }else
            {
                markImages[i]?.hidden = true
            }
        }
    }
}

//MARK: ThemeListViewController
class ThemeListViewController: UITableViewController,EditThemeViewControllerDelegate
{
    private(set) var themeService:SharelinkThemeService!
    private(set) var myThemes = [(header:String?,themes:[SharelinkTheme])]()
    private var userGuide:UserGuide!
    
    //MARK:life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUserGuide()
        self.initTableView()
        
        self.themeService = ServiceContainer.getService(SharelinkThemeService)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.changeNavigationBarColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        initThemes()
        MobClick.beginLogPageView("ThemeView")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("ThemeView")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if UserSetting.isAppstoreReviewing == false
        {
            userGuide.showGuideControllerPresentFirstTime()
        }
    }
    
    //MARK: init
    private func initTableView()
    {
        tableView.tableFooterView = UIView()
    }
    
    private func refreshTableViewFooter()
    {
        self.tableView.tableFooterView = UIView()
    }
    
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(SharelinkSetting.lang, viewName: "Theme")
        self.userGuide.initGuide(self, userId: UserSetting.userId, guideImgs: guideImgs)
    }
    
    private func initThemes()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.myThemes.removeAll()
            let customThemes = self.themeService.getAllCustomThemes()
            self.myThemes.append((header: ThemeHeaderCustom, themes: customThemes))
            self.tableView.reloadData()
            self.refreshTableViewFooter()
        })
    }
    
    //MARK:actions
    
    @IBAction func addTheme(sender: AnyObject) {
        let model = SharelinkTheme()
        model.tagId = nil
        model.tagName = nil
        model.isFocus = "true"
        model.showToLinkers = "true"
        model.type = SharelinkThemeConstant.TAG_TYPE_KEYWORD
        model.domain = SharelinkThemeConstant.TAG_DOMAIN_CUSTOM
        model.tagColor = UIColor.getRandomTextColor().toHexString()
        ServiceContainer.getService(UserService).showUserThemeEditController(self.navigationController!, editModel: model,editMode:.New, delegate: self)
    }
    
    private func removeTheme(indexPath:NSIndexPath)
    {
        let msgFormat = NSLocalizedString("SURE_REMOVE_THEME_X", comment: "Sure to remove theme %@ ?")
        let msg = String(format: msgFormat, self.myThemes[indexPath.section].themes[indexPath.row].getShowName(false))
        let alert = UIAlertController(title: NSLocalizedString("REMOVE_THEME", comment: "Remove Theme"), message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: ""), style: .Default, handler: { (action) -> Void in
            self.removeThemes([indexPath])
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel, handler: nil))
        self.showAlert(alert)
    }
    
    private func removeThemes(indexPaths:[NSIndexPath])
    {
        let needToRemoveThemes = indexPaths.map{myThemes[$0.section].themes[$0.row]}
        ServiceContainer.getService(SharelinkThemeService).removeMyThemes(needToRemoveThemes, sucCallback: { (suc) -> Void in
            if suc
            {
                let message = String(format:NSLocalizedString("REMOVED_X_THEMES", comment: ""), "\(needToRemoveThemes.count)")
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                self.initThemes()
            }else
            {
                let msg = NSLocalizedString("OPERATE_ERROR", comment: "Operate Error,Please Check Your Network")
                self.showToast(msg)
            }
        })
    }
    
    //MARK: EditThemeViewControllerDelegate
    func editThemeViewControllerSave(saveModel: SharelinkTheme, sender: EditThemeViewController) {
        if self.themeService.isThemeExists(saveModel.data)
        {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("SAME_THEME_EXISTS", comment: ""), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "I_SEE", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        self.themeService.addSharelinkTheme(saveModel){ (isSuc) -> Void in
            if isSuc
            {
                self.initThemes()
                self.showToast( NSLocalizedString("FOCUS_THEME_SUCCESS", comment: ""))
            }else
            {
                self.showToast( NSLocalizedString("FOCUS_THEME_ERROR", comment: ""))
            }
        }
    }
    
    //MARK:table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return myThemes.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myThemes[section].themes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ThemeCell.reuseId, forIndexPath: indexPath) as! ThemeCell
        cell.rootController = self
        cell.theme = myThemes[indexPath.section].themes[indexPath.row]
        cell.refreshUI()
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var actions = [UITableViewRowAction]()
        let removeThemeAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("REMOVE_THEME", comment: "Remove Theme")) { (action, indexPath) -> Void in
            self.removeTheme(indexPath)
        }
        actions.append(removeThemeAction)
        
        return actions
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
