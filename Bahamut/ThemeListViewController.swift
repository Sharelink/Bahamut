			//
//  ThemeListViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/24.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
let ThemeHeaderSystem = "THEME_HEADER_SYSTEM".localizedString()
let ThemeHeaderCustom = "THEME_HEADER_CUSTOM".localizedString()

//MARK: extension SharelinkTheme
extension SharelinkTheme
{
    func getThemeIcon() -> UIImage
    {
        let themeType = self.type.stringByReplacingOccurrencesOfString(":", withString: "")
        let named = "theme_icon_\(themeType).png"
        return UIImage.namedImageInSharelink(named) ?? UIImage.namedImageInSharelink("theme_icon_keyword.png")!
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
    static let privateImageIcon = UIImage.namedImageInSharelink("lock")!
    static let focusImageIcon = UIImage.namedImageInSharelink("heart")!
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
                rootController.playToast("A_DEFAULT_THEME".localizedString())
            }else
            {
                rootController.playToast("A_SHARELINKER_THEME".localizedString())
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
                msg = "MODIFY_THEME_SUC".localizedString()
            }else
            {
                msg = "MODIFY_THEME_ERROR".localizedString()
            }
            self.rootController.playToast(msg)
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
    
    //MARK:life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initTableView()
        self.initThemes()
        self.themeService = ServiceContainer.getService(SharelinkThemeService)
        self.themeService.addObserver(self, selector: "themesUpdated:", name: SharelinkThemeService.themesUpdated, object: nil)
        ServiceContainer.instance.addObserver(self, selector: "onServiceLogout:", name: ServiceContainer.OnServicesWillLogout, object: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.changeNavigationBarColor()
    }
    
    func onServiceLogout(sender:AnyObject)
    {
        if themeService != nil
        {
            ServiceContainer.instance.removeObserver(self)
            themeService.removeObserver(self)
            themeService = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let nc = self.navigationController as? UIOrientationsNavigationController
        {
            nc.lockOrientationPortrait = false
        }
        
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
    
    func themesUpdated(_:NSNotification)
    {
        initThemes()
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
        let msgFormat = "SURE_REMOVE_THEME_X".localizedString()
        let msg = String(format: msgFormat, self.myThemes[indexPath.section].themes[indexPath.row].getShowName(false))
        let alert = UIAlertController(title: "REMOVE_THEME".localizedString(), message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "YES".localizedString(), style: .Default, handler: { (action) -> Void in
            self.removeThemes([indexPath])
        }))
        alert.addAction(UIAlertAction(title: "CANCEL".localizedString(), style: .Cancel, handler: nil))
        self.showAlert(alert)
    }
    
    private func removeThemes(indexPaths:[NSIndexPath])
    {
        let needToRemoveThemes = indexPaths.map{myThemes[$0.section].themes[$0.row]}
        ServiceContainer.getService(SharelinkThemeService).removeMyThemes(needToRemoveThemes, sucCallback: { (suc) -> Void in
            if suc
            {
                let message = String(format:"REMOVED_X_THEMES".localizedString(), "\(needToRemoveThemes.count)")
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE".localizedString(), style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                self.initThemes()
            }else
            {
                let msg = "OPERATE_ERROR".localizedString()
                self.playToast(msg)
            }
        })
    }
    
    //MARK: EditThemeViewControllerDelegate
    func editThemeViewControllerSave(saveModel: SharelinkTheme, sender: EditThemeViewController) {
        if self.themeService.isThemeExists(saveModel.data)
        {
            let alert = UIAlertController(title: nil, message: "SAME_THEME_EXISTS".localizedString(), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "I_SEE", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        self.themeService.addSharelinkTheme(saveModel){ (isSuc) -> Void in
            if isSuc
            {
                self.initThemes()
                self.playToast( "FOCUS_THEME_SUCCESS".localizedString())
            }else
            {
                self.playToast( "FOCUS_THEME_ERROR".localizedString())
            }
        }
    }
    
    override func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
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
        let removeThemeAction = UITableViewRowAction(style: .Normal, title: "REMOVE_THEME".localizedString()) { (action, indexPath) -> Void in
            self.removeTheme(indexPath)
        }
        actions.append(removeThemeAction)
        
        return actions
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
