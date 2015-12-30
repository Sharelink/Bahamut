//
//  NewShareViewCells.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class NewShareThemeCell: NewShareCellBase,ThemeCollectionViewControllerDelegate,UITextFieldDelegate
{
    static let themesLimit = 7
    static let reuseableId = "NewShareThemeCell"
    static var tempThemes = [SharelinkTheme]()
    private var inited:Bool = false
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!{
        didSet{
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.hidden = true
        }
    }
    var themeService = ServiceContainer.getService(SharelinkThemeService)
    
    private var themeHubController:ThemeCollectionViewController!{
        didSet{
            ServiceContainer.getService(SharelinkThemeService).addObserver(self, selector: "onUserThemeUpdated:", name: SharelinkThemeService.themesUpdated, object: nil)
            themeHubController.delegate = self
        }
    }
    
    override var rootController:NewShareController!{
        didSet{
            rootView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapView:"))
        }
    }
    
    var selectedThemesCount:Int{
        return selectedIndexPath.count
    }
    var selectedThemes:[SharelinkTheme]{
        return themeHubController.selectedThemes
    }
    var selectedIndexPath = [NSIndexPath]()
    
    override func initCell()
    {
        if self.isReshare
        {
            self.initReshareThemeCell()
        }else if self.inited == false{
            self.refreshMyThemes()
        }
    }
    
    deinit{
        ServiceContainer.getService(SharelinkThemeService).removeObserver(self)
    }
    
    @IBOutlet weak var selectedThemeContainer: UIView!{
        didSet{
            selectedThemeContainer.layer.cornerRadius = 7
            selectedThemeContainer.layer.borderWidth = 1
            selectedThemeContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
            selectedThemeContainer.backgroundColor = UIColor.whiteColor()
            themeHubController  = ThemeCollectionViewController.instanceFromStoryBoard()
            selectedThemeContainer.addSubview(themeHubController.view)
        }
    }
    @IBOutlet weak var customThemeTextField: UITextField!{
        didSet{
            customThemeTextField.delegate = self
        }
    }
    
    private func startLoading()
    {
        self.themeHubController.view.hidden = true
        self.loadingIndicator.hidden = false
        self.loadingIndicator.startAnimating()
    }
    
    private func endLoading()
    {
        self.themeHubController.view.hidden = false
        self.loadingIndicator.stopAnimating()
    }
    
    private func initReshareThemeCell()
    {
        startLoading()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
            let mySystemThemes = self.themeService.getAllSystemThemes().filter{ $0.isKeywordTheme() || $0.isFeedbackTheme() || $0.isPrivateTheme() || $0.isResharelessTheme()}
            let myCustomThemes = self.themeService.getAllCustomThemes().filter{$0.isSharelinkerTheme() == false}
            var shareableThemes = [SharelinkTheme]()
            
            //filter share's tag without poster's personal tag
            let themeDatas = self.rootController.reShareModel.forTags.map{SendTagModel(json:$0)}.filter{ SharelinkThemeConstant.TAG_TYPE_SHARELINKER != $0.type }
            let themeForShare = themeDatas.map { (m) -> SharelinkTheme in
                let theme = SharelinkTheme()
                theme.type = m.type
                theme.tagName = m.name
                theme.data = m.data
                theme.tagColor = UIColor.themeColor.toHexString()
                return theme
            }
            
            shareableThemes.appendContentsOf(mySystemThemes)
            shareableThemes.appendContentsOf(themeForShare)
            shareableThemes.appendContentsOf(NewShareThemeCell.tempThemes)
            shareableThemes.appendContentsOf(myCustomThemes)
            self.themeHubController.addThemes(shareableThemes,refreshCollection: false)
            
            let selectedStartIndex = mySystemThemes.count
            let selectedEndIndex = selectedStartIndex + themeForShare.count
            let range = selectedStartIndex..<selectedEndIndex
            let selectionIndexs = range.map{NSIndexPath(forRow: $0, inSection: 0)}
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.themeHubController.reloadCollection(selectionIndexs)
                self.endLoading()
                self.inited = true
            })
        }
    }
    
    func tapView(_:UITapGestureRecognizer)
    {
        self.rootController.hideKeyBoard()
    }
    
    func onUserThemeUpdated(_:NSNotification)
    {
        refreshMyThemes()
    }
    
    private func refreshMyThemes()
    {
        startLoading()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
            let mySystemThemes = self.themeService.getAllSystemThemes().filter{ $0.isKeywordTheme() || $0.isFeedbackTheme() || $0.isPrivateTheme() || $0.isResharelessTheme()}
            let myCustomThemes = self.themeService.getAllCustomThemes().filter{$0.isSharelinkerTheme() == false}
            var shareableThemes = [SharelinkTheme]()
            shareableThemes.appendContentsOf(mySystemThemes)
            shareableThemes.appendContentsOf(NewShareThemeCell.tempThemes)
            shareableThemes.appendContentsOf(myCustomThemes)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.themeHubController.themes = shareableThemes
                self.endLoading()
                self.inited = true
            })
        }
    }
    
    func themeCellDidClick(sender: ThemeCollectionViewController, cell: ThemeCollectionCell, indexPath: NSIndexPath) {
        if cell.selected == false && selectedThemesCount >= NewShareThemeCell.themesLimit
        {
            self.rootController.showToast(NSLocalizedString("THEME_LIMIT_MESSAGE", comment: ""))
            return
        }
        if cell.selected
        {
            self.selectedIndexPath.removeElement({ (itemInArray) -> Bool in
                itemInArray.row == indexPath.row && itemInArray.section == indexPath.section
            })
        }else
        {
            self.selectedIndexPath.append(indexPath)
        }
        cell.selected = !cell.selected
    }
    
    //MARK: add temp theme
    func addTempThemeToThemesHub(theme:SharelinkTheme)
    {
        if themeHubController.addTheme(theme,refreshCollection: false) != nil
        {
            themeHubController.reloadCollection(self.selectedIndexPath)
            NewShareThemeCell.tempThemes.append(theme)
        }else
        {
            self.rootController.showToast(NSLocalizedString("THEME_ALREADY_SELECTED", comment: ""))
        }
    }
    
    //MARK: text field delegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == "\n"
        {
            if let newThemeName = customThemeTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            {
                if !newThemeName.isEmpty
                {
                    let newTheme = SharelinkTheme()
                    newTheme.tagColor = UIColor.themeColor.toHexString()
                    newTheme.tagName = newThemeName
                    newTheme.type = SharelinkThemeConstant.TAG_TYPE_KEYWORD
                    newTheme.data = newThemeName
                    customThemeTextField.text = nil
                    addTempThemeToThemesHub(newTheme)
                    return false
                }
            }
            self.rootController.showToast(NSLocalizedString("THEME_IS_EMPTY", comment: ""))
        }
        return true
    }
    
}