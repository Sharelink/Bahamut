//
//  UserGuideThemeController.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation
import UIKit

let NewUserStartGuided = "NewUserStartGuided"

class UserGuideThemeCollectionThemeCell: UICollectionViewCell
{
    @IBOutlet weak var themeNameLabel: UILabel!
    
}

class UserGuideThemeController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{

    
    static let ShowUserGuideAddFriendsControllerSegue = "UserGuideAddFriendsController"
    private var focusThemeCount = 0
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
            randomThemeCollectionView.collectionViewLayout = UICollectionViewMaxWhiteSpaceFlowLayout()
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
            performSegueWithIdentifier(UserGuideThemeController.ShowUserGuideAddFriendsControllerSegue, sender: self)
        }else
        {
            themeTextField.shakeAnimationForView()
            SystemSoundHelper.vibrate()
            self.showToast("NEED_TO_FOCUS_ONE_THEME".localizedString())
        }
    }
    
    @IBAction func refreshThemes(sender: AnyObject)
    {
        randomThemes = allRandomThemes.getRandomSubArray(10)
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
        self.showToast("NEED_INPUT_THEME_NAME".localizedString())
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
            self.showToast("SAME_THEME_EXISTS".localizedString())
        }else
        {
            self.makeToastActivity()
            themeService.addSharelinkTheme(theme) { (isSuc) -> Void in
                self.hideToastActivity()
                if isSuc
                {
                    if theme.tagName == self.themeTextField.text
                    {
                        self.themeTextField.text = ""
                    }
                    self.focusThemeCount++
                    self.showToast("FOCUS_THEME_SUCCESS".localizedString())
                }else
                {
                    self.showToast("FOCUS_THEME_ERROR".localizedString())
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
        randomThemes = allRandomThemes.getRandomSubArray(10)
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
        cell.layer.borderWidth = 2
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        calSizeLabel.text = randomThemes[indexPath.row]
        calSizeLabel.sizeToFit()
        return CGSizeMake(calSizeLabel.frame.width + 23, calSizeLabel.frame.height + 7)
    }
    
    
    
    static func startUserGuide(viewController:UIViewController) -> Bool
    {
        if !UserSetting.isSettingEnable(NewUserStartGuided)
        {
            let controller = instanceFromStoryBoard("UserGuide", identifier: "UserGuideThemeController", bundle: Sharelink.mainBundle())
            let navController = UINavigationController(rootViewController: controller)
            navController.navigationBar.barStyle = viewController.navigationController!.navigationBar.barStyle
            navController.changeNavigationBarColor()
            viewController.navigationController!.presentViewController(navController, animated: true, completion: { () -> Void in
            })
            return true
        }
        return false
    }

}