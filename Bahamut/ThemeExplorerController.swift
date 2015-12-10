//
//  ThemeExplorerController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit


//MARK: UserService Extension
extension SharelinkThemeService
{
    
    func getUserThemeItemUIModels(tags:[SharelinkTheme],selected:Bool = false) -> [UIResrouceItemModel]
    {
        return tags.map({ (tag) -> SharelinkThemeUIModel in
            let model = SharelinkThemeUIModel()
            model.selected = selected
            model.tag = tag
            return model
        })
    }
    
    func showThemeExplorerController(currentNavigationController:UINavigationController, tags:[[UIResrouceItemModel]],tagHeaders:[String]!,selectionMode:ResourceExplorerSelectMode = .Negative ,identifier:String! = "one" ,selectedTagsChanged:((tagsSeleted:[SharelinkThemeUIModel])->Void)! = nil)
    {
        let collectionController = ThemeExplorerController.instanceFromStoryBoard()
        collectionController.selectedTagsChanged = selectedTagsChanged
        collectionController.selectionMode = selectionMode
        collectionController.explorerIdentifier = identifier
        collectionController.items = tags
        collectionController.tagHeaders = tagHeaders
        collectionController.isMainTabController = false
        currentNavigationController.pushViewController(collectionController, animated: true)
    }
}

class SharelinkThemeUIModel: UIResrouceItemModel
{
    var tag:SharelinkTheme!
    override var canEdit:Bool{
        return tag.isSystemTag() == false
    }
}

class ThemeExplorerViewCell: UIResourceItemCell
{
    var cellColor:UIColor!
    override func layoutSubviews() {
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 2
        super.layoutSubviews()
    }
    override func update() {
        super.update()
        if let model = self.model as? SharelinkThemeUIModel
        {
            self.cellColor = UIColor(hexString: model.tag.tagColor)
            self.layer.borderColor = (cellColor ?? UIColor.themeColor).CGColor
            if tagNameLabel != nil
            {
                tagNameLabel.text = model.tag.getShowName()
                tagNameLabel.textColor = self.cellColor ?? UIColor.themeColor
            }
            if focusMark != nil
            {
                focusMark.hidden = "false" == model.tag.isFocus
            }
        }
    }
    @IBOutlet weak var focusMark: UIImageView!
    @IBOutlet weak var tagNameLabel: UILabel!
    
}

let ThemeHeaderSystem = NSLocalizedString("TAG_HEADER_SYSTEM", comment:"Sharelink")
let ThemeHeaderCustom = NSLocalizedString("TAG_HEADER_CUSTOM", comment:"Cutstom")

class ThemeExplorerController: UIResourceExplorerController,UIResourceExplorerDelegate,UserThemeEditControllerDelegate
{
    private(set) var themeService:SharelinkThemeService!
    var explorerIdentifier:String! = "one"
    var selectedTagsChanged:((tagsSeleted:[SharelinkThemeUIModel])->Void)!
    var tagHeaders:[String]!
    var isMainTabController = true
    private var userGuide:UserGuide!
    
    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isMainTabController
        {
            self.initUserGuide()
        }
        self.items = [[UIResrouceItemModel]]()
        themeService = ServiceContainer.getService(SharelinkThemeService)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.delegate = self
        self.changeNavigationBarColor()
        updateBarButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initItems()
        MobClick.beginLogPageView("ThemeView")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("ThemeView")
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        notifyItemSelectState()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if isMainTabController
        {
            self.userGuide.showGuideControllerPresentFirstTime()
        }
    }
    
    private func initUserGuide()
    {
        self.userGuide = UserGuide()
        let guideImgs = UserGuideAssetsConstants.getViewGuideImages(SharelinkSetting.lang, viewName: "Theme")
        self.userGuide.initGuide(self, userId: SharelinkSetting.userId, guideImgs: guideImgs)
    }
    
    private func initItems()
    {
        if isMainTabController
        {
            self.items.removeAll()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tagHeaders = [String]()
                self.selectionMode = ResourceExplorerSelectMode.Negative
                let customtags = self.themeService.getAllCustomThemes()
                if customtags.count > 0
                {
                    let customTagItems = self.themeService.getUserThemeItemUIModels(customtags)
                    self.items.append(customTagItems)
                    self.tagHeaders.append(ThemeHeaderCustom)
                }
                self.collectionView.reloadData()
            })
        }
        
    }
    
    //MARK: UserThemeEditControllerDelegate
    
    func tagEditControllerSave(saveModel: SharelinkThemeUIModel, sender: UserThemeEditController)
    {
        if sender.editMode == .New
        {
            if themeService.isThemeExists(saveModel.tag.data)
            {
                let alert = UIAlertController(title: nil, message: NSLocalizedString("SAME_TAG_EXISTS", comment: ""), preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            themeService.addSharelinkTheme(saveModel.tag){ (isSuc) -> Void in
                if isSuc
                {
                    if self.isMainTabController
                    {
                        self.initItems()
                    }else
                    {
                        if self.items.count == 0
                        {
                            self.items.append([UIResrouceItemModel]())
                        }
                        self.items[0].append(saveModel)
                        self.uiCollectionView.reloadData()
                    }
                    
                    self.showToast( NSLocalizedString("FOCUS_TAG_SUCCESS", comment: "Focus successful!"))
                }else
                {
                    self.showToast( NSLocalizedString("FOCUS_TAG_FAILED", comment: "focus tag error , please check your network"))
                }
            }
        }else{
            themeService.updateTheme(saveModel.tag){
                self.uiCollectionView.reloadData()
            }
        }
    }
    
    //MARK: delegate
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.items.count
    }
    
//    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView{
//        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "tagSectionHeader", forIndexPath: indexPath)
//        if let title = header.viewWithTag(1) as? UILabel
//        {
//            title.text = self.tagHeaders[indexPath.section]
//        }
//        return header
//    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(3, 3, 3, 3);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        if let model = items[indexPath.section][indexPath.row] as? SharelinkThemeUIModel
        {
            let uiLabel = UILabel()
            uiLabel.font = UIFont.systemFontOfSize(17)
            uiLabel.text = model.tag.getShowName()
            uiLabel.sizeToFit()
            return CGSizeMake(uiLabel.bounds.width + 7 + 32, 32)
        }
        return CGSizeZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return CGFloat(3)
    }
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let tagsChanged = self.selectedTagsChanged
        {
            tagsChanged(tagsSeleted: itemModels as! [SharelinkThemeUIModel])
        }
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel,indexPath:NSIndexPath) -> Void, sender: UIResourceExplorerController!)
    {
        let model = SharelinkThemeUIModel()
        model.tag = SharelinkTheme()
        model.tag.tagId = nil
        model.tag.tagName = nil
        model.tag.isFocus = "true"
        model.tag.showToLinkers = "true"
        model.tag.type = SharelinkThemeConstant.TAG_TYPE_KEYWORD
        model.tag.domain = SharelinkThemeConstant.TAG_DOMAIN_CUSTOM
        model.tag.tagColor = UIColor.getRandomTextColor().toHexString()
        ServiceContainer.getService(UserService).showUserThemeEditController(self.navigationController!, editModel: model,editMode:.New, delegate: self)
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let models = itemModels as? [SharelinkThemeUIModel]
        {
            ServiceContainer.getService(SharelinkThemeService).removeMyThemes(models.map{$0.tag!}, sucCallback: { () -> Void in
                let message = String(format:NSLocalizedString("REMOVED_X_TAGS", comment: "Remove %@ Tags"), "\(models.count)")
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            })
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!)
    {
        if let model = itemModel as? SharelinkThemeUIModel
        {
            if model.tag.isSystemTag() || model.tag.isSharelinkerTag()
            {
                if model.tag.isSystemTag()
                {
                    self.showToast(NSLocalizedString("A_DEFAULT_TAG", comment: "It's a sharelink default tag!"))
                }else
                {
                    self.showToast(NSLocalizedString("A_SHARELINKER_TAG", comment: ""))
                }
                return
            }
            ServiceContainer.getService(UserService).showUserThemeEditController(self.navigationController!, editModel: model,editMode:.Edit, delegate: self)
        }
    }
    
    private func updateBarButtons()
    {
        self.navigationItem.rightBarButtonItems?.removeAll()
        if editing
        {
            self.navigationItem.rightBarButtonItems = [doneButton,deleteButton]
        }else
        {
            self.navigationItem.rightBarButtonItems = [addButton,editButton]
        }
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    @IBOutlet weak var uiCollectionView: UICollectionView!
    
    override func getCollectionView() -> UICollectionView {
        return uiCollectionView
    }
    
    override func getCellReuseIdentifier() -> String {
        return "ThemeItemCell"
    }
    
    @IBAction func addTag(sender: AnyObject) {
        addItem(sender)
    }
    
    @IBAction func deleteTag(sender: AnyObject) {
        deleteItem(sender)
    }
    
    @IBAction func finishEdit(sender: AnyObject) {
        editing = !editing
        updateBarButtons()
    }
    
    @IBAction func editTags(sender: AnyObject)
    {
        editItems(sender)
        updateBarButtons()

    }
    
    static func instanceFromStoryBoard() -> ThemeExplorerController
    {
        return instanceFromStoryBoard("Main", identifier: "ThemeExplorerController") as! ThemeExplorerController
    }
}

