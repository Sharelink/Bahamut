//
//  UITagExplorerController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: UserService Extension
extension SharelinkTagService
{
    
    func getUserTagsResourceItemModels(tags:[SharelinkTag],selected:Bool = false) -> [UIResrouceItemModel]
    {
        return tags.map({ (tag) -> UISharelinkTagItemModel in
            let model = UISharelinkTagItemModel()
            model.selected = selected
            model.tagModel = tag
            return model
        })
    }
    
    func showTagExplorerController(currentNavigationController:UINavigationController, tags:[UIResrouceItemModel],selectionMode:ResourceExplorerSelectMode = .Negative ,identifier:String! = "one" ,selectedTagsChanged:((tagsSeleted:[UISharelinkTagItemModel])->Void)! = nil)
    {
        
        let collectionController = UITagExplorerController.instanceFromStoryBoard()
        collectionController.selectedTagsChanged = selectedTagsChanged
        collectionController.selectionMode = selectionMode
        collectionController.explorerIdentifier = identifier
        collectionController.items = tags
        currentNavigationController.pushViewController(collectionController, animated: true)
    }
}

class UISharelinkTagItemModel: UIResrouceItemModel
{
    var tagModel:SharelinkTag!
}

class UITagExplorerViewCell: UIResourceItemCell
{
    override func layoutSubviews() {
        self.layer.cornerRadius = 7
        super.layoutSubviews()
    }
    override func update() {
        super.update()
        if let tagModel = self.model as? UISharelinkTagItemModel
        {
            if tagNameLabel != nil
            {
                tagNameLabel.text = tagModel.tagModel.tagName
            }
            self.backgroundColor = UIColor(hexString: tagModel.tagModel.tagColor)
        }
    }
    @IBOutlet weak var tagNameLabel: UILabel!
    
}

class UITagExplorerController: UIResourceExplorerController,UIResourceExplorerDelegate,UIUserTagEditControllerDelegate
{
    var explorerIdentifier:String!
    var selectedTagsChanged:((tagsSeleted:[UISharelinkTagItemModel])->Void)!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        notifyItemSelectState()
    }
    
    func tagEditControllerSave(saveModel: UISharelinkTagItemModel, sender: UIUserTagEditController)
    {
        let service = ServiceContainer.getService(SharelinkTagService)
        self.view.makeToastActivityWithMessage(message: "Saveing Tag")
        if sender.editMode == .New
        {
            service.addSharelinkTag(saveModel.tagModel){
                self.items.append(saveModel)
                self.view.hideToastActivity()
                self.uiCollectionView.reloadData()
            }
        }else{
            service.updateTag(saveModel.tagModel){
                self.view.hideToastActivity()
                self.uiCollectionView.reloadData()
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(3, 3, 3, 3);
    }
    
    override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        if let model = items[indexPath.row] as? UISharelinkTagItemModel
        {
            let uiLabel = UILabel()
            uiLabel.font = UIFont.systemFontOfSize(17)
            uiLabel.text = model.tagModel.tagName
            uiLabel.sizeToFit()
            return CGSizeMake(uiLabel.bounds.width + 7, 26)
        }
        return CGSizeZero
    }
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let tagsChanged = self.selectedTagsChanged
        {
            tagsChanged(tagsSeleted: itemModels as! [UISharelinkTagItemModel])
        }
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel) -> Void, sender: UIResourceExplorerController!)
    {
        let newTag = UISharelinkTagItemModel()
        newTag.tagModel = SharelinkTag()
        newTag.tagModel.tagId = nil
        newTag.tagModel.tagName = "newTag"
        newTag.tagModel.isFocus = "true"
        newTag.tagModel.tagColor = UIColor(hex: arc4random()).toHexString()
        ServiceContainer.getService(UserService).showUIUserTagEditController(self.navigationController!, editModel: newTag,editMode:.New, delegate: self)
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let models = itemModels as? [UISharelinkTagItemModel]
        {
            ServiceContainer.getService(SharelinkTagService).removeMyTags(models.map{$0.tagModel!}, sucCallback: { () -> Void in
                self.view.makeToast(message: "Remove \(models.count) Tags", duration: 0, position: HRToastPositionCenter)
                
            })
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!)
    {
        if let tagModel = itemModel as? UISharelinkTagItemModel
        {
            ServiceContainer.getService(UserService).showUIUserTagEditController(self.navigationController!, editModel: tagModel,editMode:.Edit, delegate: self)
        }
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
    
    @IBAction func editTags(sender: AnyObject)
    {
        editItems(sender)
    }
    
    static func instanceFromStoryBoard() -> UITagExplorerController
    {
        return instanceFromStoryBoard("Component", identifier: "UITagExplorerController") as! UITagExplorerController
    }
}

