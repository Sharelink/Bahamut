//
//  UIUserTagCollectionController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

//MARK: UserService Extension
extension UserService
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
    
    func showTagCollectionControllerView(currentNavigationController:UINavigationController, tags:[UIResrouceItemModel],selectionMode:ResourceExplorerSelectMode = .Negative ,selectedTagsChanged:((tagsSeleted:[UISharelinkTagItemModel])->Void)! = nil)
    {
        
        let collectionController = UIUserTagCollectionController.instanceFromStoryBoard()
        collectionController.selectedTagsChanged = selectedTagsChanged
        collectionController.selectionMode = selectionMode
        collectionController.items = tags
        currentNavigationController.pushViewController(collectionController, animated: true)
    }
}

class UISharelinkTagItemModel: UIResrouceItemModel
{
    var tagModel:SharelinkTag!
}

class UserTagCollectionViewCell: UIResourceItemCell
{
    
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

class UIUserTagCollectionController: UIResourceExplorerController,UIResourceExplorerDelegate,UIUserTagEditControllerDelegate
{
    var selectedTagsChanged:((tagsSeleted:[UISharelinkTagItemModel])->Void)!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    func tagEditControllerSave(saveModel: UISharelinkTagItemModel, sender: UIUserTagEditController)
    {
        let service = ServiceContainer.getService(UserTagService)
        if sender.editMode == .New
        {
            service.addSharelinkTag(saveModel.tagModel){
                self.items.append(saveModel)
                self.uiCollectionView.reloadData()
            }
        }else{
            service.updateTag(saveModel.tagModel){
                self.uiCollectionView.reloadData()
            }
        }
    }
    
    func resourceExplorerAddItem(completedHandler: (itemModel: UIResrouceItemModel) -> Void, sender: UIResourceExplorerController!)
    {
        let newTag = UISharelinkTagItemModel()
        newTag.tagModel = SharelinkTag()
        newTag.tagModel.tagId = nil
        newTag.tagModel.tagName = "newTag"
        newTag.tagModel.tagColor = UIColor(hex: arc4random()).toHexString()
        ServiceContainer.getService(UserService).showUIUserTagEditController(self.navigationController!, editModel: newTag,editMode:.New, delegate: self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let tagsChanged = self.selectedTagsChanged
        {
            tagsChanged(tagsSeleted: self.items.filter{ $0.selected} as! [UISharelinkTagItemModel])
        }
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        if let models = itemModels as? [UISharelinkTagItemModel]
        {
            ServiceContainer.getService(UserTagService).removeMyTags(models.map{$0.tagModel!}, sucCallback: { () -> Void in
                self.view.makeToast(message: "Remove \(models.count) Tags")
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
    
    static func instanceFromStoryBoard() -> UIUserTagCollectionController
    {
        return instanceFromStoryBoard("Component", identifier: "userTagCollectionViewController") as! UIUserTagCollectionController
    }
}

