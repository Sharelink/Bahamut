//
//  UserGuideThemeController.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

#if APP_VERSION

class UserGuideThemeCollectionThemeCell: UICollectionViewCell
{
    @IBOutlet weak var themeNameLabel: UILabel!
    
}

class UserGuideThemeController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{

    
    static let ShowUserGuideAddFriendsControllerSegue = "UserGuideAddFriendsController"
    private var focusThemeCount = 0
    var hotThemes:[String]!
    private var allRandomThemes:[String]!
    private var randomThemes:[String]!{
        didSet{
            if randomThemeCollectionView != nil
            {
                randomThemeCollectionView.reloadData()
            }
        }
    }
    private var themeService:SharelinkThemeService!
    @IBOutlet weak var randomThemeCollectionView: UICollectionView!{
        didSet{
            randomThemeCollectionView.delegate = self
            randomThemeCollectionView.dataSource = self
            randomThemeCollectionView.backgroundColor = UIColor.whiteColor()
        }
    }
    @IBOutlet weak var themeTextField: UITextField!
    @IBAction func nextStep(sender: AnyObject)
    {
        if focusThemeCount > 0 || themeService.getAllCustomThemes().count > 0
        {
            MobClick.event("UserGuide_ToAddInviter")
            ServiceContainer.getService(NotificationService).setMute(false)
            performSegueWithIdentifier(UserGuideThemeController.ShowUserGuideAddFriendsControllerSegue, sender: self)
        }else
        {
            themeTextField.shakeAnimationForView()
            SystemSoundHelper.vibrate()
            self.playToast("NEED_TO_FOCUS_ONE_THEME".localizedString())
        }
    }
    
    private func getHotThemes()
    {
        let req = GetHotThemesRequest()
        SharelinkSDK.sharedInstance.getShareLinkClient().execute(req) { (result:SLResult<GetHotThemesRequest.HotThemes>) -> Void in
            if let result = result.returnObject
            {
                if let themes = result.themes
                {
                    self.hotThemes = themes
                }
            }
        }
    }
    
    private func reloadThemes()
    {
        var themes:[String]! = nil
        if hotThemes != nil && hotThemes.count > 0
        {
            themes = hotThemes.getRandomSubArray(3)
            let rthemes = allRandomThemes.getRandomSubArray(7)
            themes.appendContentsOf(rthemes)
        }else
        {
            getHotThemes()
            themes = allRandomThemes.getRandomSubArray(10)
        }
        randomThemes = themes
    }
    
    @IBAction func refreshThemes(sender: AnyObject)
    {
        reloadThemes()
    }
    
    @IBAction func addThemeFocus(sender: AnyObject)
    {
        if let themename = self.themeTextField.text
        {
            if String.isNullOrEmpty(themename) == false
            {
                addTheme(self.themeTextField.text!)
                return
            }
        }
        themeTextField.shakeAnimationForView()
        SystemSoundHelper.vibrate()
        self.playToast("NEED_INPUT_THEME_NAME".localizedString())
    }
    
    func tapCell(a:UITapGestureRecognizer)
    {
        if let cell = a.view as? UserGuideThemeCollectionThemeCell
        {
            cell.animationMaxToMin(0.1, maxScale: 1.2, completion: { () -> Void in
                if let themeName = cell.themeNameLabel.text
                {
                    if String.isNullOrEmpty(themeName) == false
                    {
                        self.addTheme(themeName)
                    }
                }
            })
        }
    }
    
    private func addTheme(themeName:String)
    {
        MobClick.event("UserGuide_AddTheme")
        let theme = SharelinkTheme()
        theme.tagId = nil
        theme.tagName = themeName
        theme.isFocus = "true"
        theme.showToLinkers = "true"
        theme.data = themeName
        theme.type = SharelinkThemeConstant.TAG_TYPE_KEYWORD
        theme.domain = SharelinkThemeConstant.TAG_DOMAIN_CUSTOM
        theme.tagColor = UIColor.themeColor.toHexString()
        if themeService.isThemeExists(theme.data)
        {
            self.playToast("SAME_THEME_EXISTS".localizedString())
        }else
        {
            let hud = self.showActivityHud()
            themeService.addSharelinkTheme(theme) { (isSuc) -> Void in
                hud.hideAsync(true)
                if isSuc
                {
                    if theme.tagName == self.themeTextField.text
                    {
                        self.themeTextField.text = ""
                    }
                    self.focusThemeCount++
                    self.playToast("FOCUS_THEME_SUCCESS".localizedString())
                }else
                {
                    self.playToast("FOCUS_THEME_ERROR".localizedString())
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        themeService = ServiceContainer.getService(SharelinkThemeService)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapView:"))
        let url = Sharelink.mainBundle().pathForResource("StartupThemes", ofType: "conf")!
        let themesText = PersistentFileHelper.readTextFile(url)!
        allRandomThemes = themesText.split(",")
        ServiceContainer.getService(NotificationService).setMute(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadThemes()
    }
    
    func tapView(_:UITapGestureRecognizer)
    {
        self.hideKeyBoard()
    }
    
    //MARK: CollectionView datasource delegate
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UserGuideThemeCollectionThemeCell", forIndexPath: indexPath) as! UserGuideThemeCollectionThemeCell
        cell.themeNameLabel.textColor = UIColor.getRondomColorIn(ColorSets.textColors)
        cell.themeNameLabel.font = calSizeLabel.font
        cell.themeNameLabel.text = randomThemes[indexPath.row]
        cell.layer.cornerRadius = (calSizeLabel.frame.height + 7) / 2
        cell.layer.borderColor = UIColor.themeColor.CGColor
        cell.layer.borderWidth = 1
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCell:"))
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return randomThemes?.count ?? 0
    }
    
    private var calSizeLabel = UILabel(){
        didSet{
            calSizeLabel.font = UIFont(name: "System", size: 23)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 3, left: 3, bottom: 7, right: 3)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        calSizeLabel.text = randomThemes[indexPath.row]
        calSizeLabel.sizeToFit()
        return CGSizeMake(calSizeLabel.frame.width + 23, calSizeLabel.frame.height + 7)
    }

}

#endif