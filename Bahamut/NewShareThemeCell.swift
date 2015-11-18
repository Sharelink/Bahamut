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

class NewShareThemeCell: NewShareCellBase,UITagCollectionViewControllerDelegate,UITextFieldDelegate
{
    static let themesLimit = 7
    static let reuseableId = "NewShareThemeCell"
    override func initCell()
    {
        myThemeController = UITagCollectionViewController.instanceFromStoryBoard()
        self.rootView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapView:"))
        if isReshare
        {
            initReshareThemeCell()
        }
    }
    
    var myThemeController:UITagCollectionViewController!
        {
        didSet{
            myThemeContainer = UIView()
            myThemeController.delegate = self
        }
    }
    
    private var myThemeContainer:UIView!{
        didSet{
            myThemeContainer.layer.cornerRadius = 7
            myThemeContainer.layer.borderWidth = 1
            myThemeContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
            myThemeContainer.backgroundColor = UIColor.whiteColor()
        }
    }
    
    @IBOutlet weak var selectedThemeContainer: UIView!{
        didSet{
            selectedThemeContainer.layer.cornerRadius = 7
            selectedThemeContainer.layer.borderWidth = 1
            selectedThemeContainer.layer.borderColor = UIColor.lightGrayColor().CGColor
            selectedThemeContainer.backgroundColor = UIColor.whiteColor()
            selectedThemeController  = UITagCollectionViewController.instanceFromStoryBoard()
            selectedThemeContainer.addSubview(selectedThemeController.view)
        }
    }
    @IBOutlet weak var customThemeTextField: UITextField!{
        didSet{
            customThemeTextField.delegate = self
        }
    }
    
    private func initReshareThemeCell()
    {
        //filter share's tag without poster's personal tag
        let tagDatas = shareModel.forTags.map{SendTagModel(json:$0)}.filter{ SharelinkTagConstant.TAG_TYPE_SHARELINKER != $0.type }
        for m in tagDatas
        {
            let tag = SharelinkTag()
            tag.type = m.type
            tag.tagName = m.name
            tag.data = m.data
            tag.tagColor = UIColor.getRandomTextColor().toHexString()
            self.selectedThemeController.addTag(tag)
        }
    }
    
    @IBAction func themeHubClick(sender: AnyObject) {
        if myThemeContainer.superview != nil
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.hideMyThemesCollection()
            })
            
        }else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.showMyThemesCollection()
                MobClick.event("SelectThemeButton")
            })
            
        }
    }
    
    func tapView(_:UITapGestureRecognizer)
    {
        if myThemeContainer.superview != nil
        {
            hideMyThemesCollection()
        }
        self.rootController.hideKeyBoard()
    }
    
    //MARK: seletectd tags
    var selectedThemeController:UITagCollectionViewController!{
        didSet{
            selectedThemeController.delegate = self
        }
    }
    
    func initMyThemes()
    {
        let tagService = ServiceContainer.getService(SharelinkTagService)
        let mySystemTags = tagService.getAllSystemTags().filter{ $0.isKeywordTag() || $0.isFeedbackTag() || $0.isPrivateTag() || $0.isResharelessTag()}
        
        let myCustomTags = tagService.getAllCustomTags().filter{$0.isSharelinkerTag() == false}
        var shareableTags = [SharelinkTag]()
        shareableTags.appendContentsOf(mySystemTags)
        shareableTags.appendContentsOf(myCustomTags)
        self.myThemeController.tags = shareableTags
    }
    
    private func showMyThemesCollection()
    {
        initMyThemes()
        self.rootView.addSubview(myThemeContainer)
        myThemeContainer.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, selectedThemeContainer.bounds.width, 0)
        self.myThemeContainer.addSubview(myThemeController.view)
        let height = CGFloat(self.frame.height)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        myThemeContainer.frame = CGRectMake(selectedThemeContainer.frame.origin.x , self.frame.origin.y - height ,self.selectedThemeContainer.bounds.width, height)
        self.rootView.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    private func hideMyThemesCollection()
    {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        self.rootView.layoutIfNeeded()
        UIView.commitAnimations()
        myThemeContainer.removeFromSuperview()
    }
    
    func tagDidTap(sender: UITagCollectionViewController, indexPath: NSIndexPath)
    {
        if sender == myThemeController
        {
            let tag = myThemeController.tags[indexPath.row]
            if addThemeToSelectedThemes(tag)
            {
                let tagSortableObj = tag.getSortableObject()
                tagSortableObj.compareValue = NSNumber(double: NSDate().timeIntervalSince1970)
                tagSortableObj.saveModel()
            }else
            {
                
            }
        }else if sender == selectedThemeController
        {
            sender.removeTag(indexPath)
        }
    }
    
    func addThemeToSelectedThemes(theme:SharelinkTag) -> Bool
    {
        if selectedThemeController.tags != nil && selectedThemeController.tags.count >= NewShareThemeCell.themesLimit
        {
            self.rootController.showToast(NSLocalizedString("TAG_LIMIT_MESSAGE", comment: "can't not add more tags!"))
            return false
        }
        if !selectedThemeController.addTag(theme)
        {
            self.rootController.showToast(NSLocalizedString("TAG_ALREADY_SELECTED", comment: "tag has been added!"))
            return true
        }else
        {
            return false
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
                    let newTheme = SharelinkTag()
                    newTheme.tagColor = UIColor.getRandomTextColor().toHexString()
                    newTheme.tagName = newThemeName
                    newTheme.type = SharelinkTagConstant.TAG_TYPE_KEYWORD
                    newTheme.data = newThemeName
                    customThemeTextField.text = nil
                    addThemeToSelectedThemes(newTheme)
                    return false
                }
            }
            self.rootController.showToast(NSLocalizedString("TAG_IS_EMPTY", comment: "there is nothing!"))
        }
        return true
    }
    
}