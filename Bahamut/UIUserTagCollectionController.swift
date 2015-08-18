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
    
    func getUserTagsResourceItemModels(tags:[UserTag]) -> [UIResrouceItemModel]
    {
        return tags.map({ (tag) -> UserTagModel in
            let model = UserTagModel()
            model.tagModel = tag
            return model
        })
    }
    
    func showTagCollectionControllerView(currentNavigationController:UINavigationController,tags:[UIResrouceItemModel],selectionMode:ResourceExplorerSelectMode = .Negative ,selectedTagsChanged:((tagsSeleted:[UserTagModel])->Void)! = nil)
    {
        let storyBoard = UIStoryboard(name: "Component", bundle: NSBundle.mainBundle())
        let collectionController = storyBoard.instantiateViewControllerWithIdentifier("tagCollectionViewController") as! UIUserTagCollectionController
        collectionController.items = tags
        collectionController.selectedTagsChanged = selectedTagsChanged
        collectionController.selectionMode = selectionMode
        currentNavigationController.pushViewController(collectionController, animated: true)
    }
}

class UserTagModel: UIResrouceItemModel
{
    var tagModel:UserTag!
}

class UserTagCollectionViewCell: UIResourceItemCell
{
    
    @IBOutlet weak var tagNameLabel: UILabel!{
        didSet{
            if let tagModel = self.model as? UserTagModel
            {
                tagNameLabel.text = tagModel.tagModel.tagName
            }
        }
    }
    
}

class UIUserTagCollectionController: UIResourceExplorerController,UIResourceExplorerDelegate,UIUserTagEditControllerDelegate
{
    var selectedTagsChanged:((tagsSeleted:[UserTagModel])->Void)!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    func tagEditControllerSave(saveModel: UserTagModel, sender: UIUserTagEditController)
    {
        let service = ServiceContainer.getService(UserService)
        if sender.editMode == .New
        {
            service.addUserTag(saveModel.tagModel){
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
        let newTag = UserTagModel()
        newTag.tagModel = UserTag()
        newTag.tagModel.tagId = nil
        newTag.tagModel.tagName = "newTag"
        newTag.tagModel.tagColor = UIColor.redColor().toHexString()
        ServiceContainer.getService(UserService).showUIUserTagEditController(self.navigationController!, editModel: newTag,editMode:.New, delegate: self)
    }
    
    func resourceExplorerItemDeSelected(itemModel: UIResrouceItemModel, index: Int, sender: UIResourceExplorerController!)
    {
        if let tagsChanged = self.selectedTagsChanged
        {
            tagsChanged(tagsSeleted: self.items.filter{ $0.selected} as! [UserTagModel])
        }
        
    }
    
    func resourceExplorerItemSelected(itemModel: UIResrouceItemModel, index: Int, sender: UIResourceExplorerController!)
    {
        if let tagsChanged = self.selectedTagsChanged
            {
                tagsChanged(tagsSeleted: self.items.filter{ $0.selected} as! [UserTagModel])
        }
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!)
    {
        //TODO: finished this
        
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!)
    {
        if let tagModel = itemModel as? UserTagModel
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
}

