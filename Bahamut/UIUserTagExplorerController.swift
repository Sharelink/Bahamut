//
//  UITagExplorerController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import SharelinkSDK

//MARK: UserService Extension
extension SharelinkTagService
{
    
    func getUserTagsResourceItemModels(tags:[SharelinkTag],selected:Bool = false) -> [UIResrouceItemModel]
    {
        return tags.map({ (tag) -> UISharelinkTagItemModel in
            let model = UISharelinkTagItemModel()
            model.selected = selected
            model.tag = tag
            return model
        })
    }
    
    func showTagExplorerController(currentNavigationController:UINavigationController, tags:[[UIResrouceItemModel]],tagHeaders:[String]!,selectionMode:ResourceExplorerSelectMode = .Negative ,identifier:String! = "one" ,selectedTagsChanged:((tagsSeleted:[UISharelinkTagItemModel])->Void)! = nil)
    {
        let collectionController = UITagExplorerController.instanceFromStoryBoard()
        collectionController.selectedTagsChanged = selectedTagsChanged
        collectionController.selectionMode = selectionMode
        collectionController.explorerIdentifier = identifier
        collectionController.items = tags
        collectionController.tagHeaders = tagHeaders
        collectionController.isMainTagExplorerController = false
        currentNavigationController.pushViewController(collectionController, animated: true)
    }
}

class UISharelinkTagItemModel: UIResrouceItemModel
{
    var tag:SharelinkTag!
    override var canEdit:Bool{
        return tag.isSystemTag() == false
    }
}

class UITagExplorerViewCell: UIResourceItemCell
{
    override func layoutSubviews() {
        self.layer.cornerRadius = 7
        super.layoutSubviews()
    }
    override func update() {
        super.update()
        if let model = self.model as? UISharelinkTagItemModel
        {
            if tagNameLabel != nil
            {
                tagNameLabel.text = model.tag.getShowName()
            }
            if focusMark != nil
            {
                focusMark.hidden = "false" == model.tag.isFocus
            }
            self.backgroundColor = UIColor(hexString: model.tag.tagColor)
        }
    }
    @IBOutlet weak var focusMark: UIImageView!
    @IBOutlet weak var tagNameLabel: UILabel!
    
}

let TagHeaderSystem = NSLocalizedString("TAG_HEADER_SYSTEM", comment:"Sharelink")
let TagHeaderCustom = NSLocalizedString("TAG_HEADER_CUSTOM", comment:"Cutstom")

class UITagExplorerController: UIResourceExplorerController,UIResourceExplorerDelegate,UIUserTagEditControllerDelegate
{
    private(set) var tagService:SharelinkTagService!
    var explorerIdentifier:String! = "one"
    var selectedTagsChanged:((tagsSeleted:[UISharelinkTagItemModel])->Void)!
    var tagHeaders:[String]!
    var isMainTagExplorerController = true
    override func viewDidLoad() {
        super.viewDidLoad()
        self.items = [[UIResrouceItemModel]]()
        tagService = ServiceContainer.getService(SharelinkTagService)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.delegate = self
        self.changeNavigationBarColor()
        updateBarButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initItems()
    }

    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var editButton: UIBarButtonItem!
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        notifyItemSelectState()
    }
    
    func initItems()
    {
        if isMainTagExplorerController
        {
            self.items.removeAll()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tagHeaders = [String]()
                self.selectionMode = ResourceExplorerSelectMode.Negative
                let customtags = self.tagService.getAllCustomTags()
                let customTagItems = self.tagService.getUserTagsResourceItemModels(customtags)
                self.items.append(customTagItems)
                self.tagHeaders.append(TagHeaderCustom)
                self.collectionView.reloadData()
            })
        }
        
    }
    
    func tagEditControllerSave(saveModel: UISharelinkTagItemModel, sender: UIUserTagEditController)
    {
        if sender.editMode == .New
        {
            if tagService.isTagExists(saveModel.tag.data)
            {
                let alert = UIAlertController(title: nil, message: NSLocalizedString("SAME_TAG_EXISTS", comment: ""), preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "I_SEE", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            tagService.addSharelinkTag(saveModel.tag){ (isSuc) -> Void in
                if isSuc
                {
                    self.items[0].append(saveModel)
                    self.uiCollectionView.reloadData()
                    self.view.makeToast(message:NSLocalizedString("FOCUS_TAG_SUCCESS", comment: "Focus successful!"))
                }else
                {
                    self.view.makeToast(message:NSLocalizedString("FOCUS_TAG_FAILED", comment: "focus tag error , please check your network"))
                }
            }
        }else{
            tagService.updateTag(saveModel.tag){
                self.uiCollectionView.reloadData()
            }
        }
    }
    
    //MARK: delegate
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView{
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "tagSectionHeader", forIndexPath: indexPath)
        if let title = header.viewWithTag(1) as? UILabel
        {
            title.text = self.tagHeaders[indexPath.section]
        }
        return header
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(3, 3, 3, 3);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        if let model = items[indexPath.section][indexPath.row] as? UISharelinkTagItemModel
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
        return CGFloat(4)
    }
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let tagsChanged = self.selectedTagsChanged
        {
            tagsChanged(tagsSeleted: itemModels as! [UISharelinkTagItemModel])
        }
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel,indexPath:NSIndexPath) -> Void, sender: UIResourceExplorerController!)
    {
        let model = UISharelinkTagItemModel()
        model.tag = SharelinkTag()
        model.tag.tagId = nil
        model.tag.tagName = nil
        model.tag.isFocus = "true"
        model.tag.showToLinkers = "true"
        model.tag.type = SharelinkTagConstant.TAG_TYPE_KEYWORD
        model.tag.domain = SharelinkTagConstant.TAG_DOMAIN_CUSTOM
        model.tag.tagColor = UIColor(hex: arc4random()).toHexString()
        ServiceContainer.getService(UserService).showUIUserTagEditController(self.navigationController!, editModel: model,editMode:.New, delegate: self)
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let models = itemModels as? [UISharelinkTagItemModel]
        {
            ServiceContainer.getService(SharelinkTagService).removeMyTags(models.map{$0.tag!}, sucCallback: { () -> Void in
                let message = String(format:NSLocalizedString("REMOVED_X_TAGS", comment: "Remove %@ Tags"), "\(models.count)")
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("I_SEE", comment: ""), style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            })
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!)
    {
        if let model = itemModel as? UISharelinkTagItemModel
        {
            if model.tag.isSystemTag() || model.tag.isSharelinkerTag()
            {
                var alert:UIAlertController!
                if model.tag.isSystemTag()
                {
                    alert = UIAlertController(title:nil, message:NSLocalizedString("A_DEFAULT_TAG", comment: "It's a sharelink default tag!"), preferredStyle: .Alert)
                }else
                {
                    alert = UIAlertController(title:nil, message:NSLocalizedString("A_SHARELINKER_TAG", comment: ""), preferredStyle: .Alert)
                }
                alert.addAction(UIAlertAction(title:NSLocalizedString("I_SEE", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            ServiceContainer.getService(UserService).showUIUserTagEditController(self.navigationController!, editModel: model,editMode:.Edit, delegate: self)
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
        return "TagItemCell"
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
    
    static func instanceFromStoryBoard() -> UITagExplorerController
    {
        return instanceFromStoryBoard("Main", identifier: "UITagExplorerController") as! UITagExplorerController
    }
}

