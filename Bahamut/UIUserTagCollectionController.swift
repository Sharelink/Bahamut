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
    
    func showTagCollectionControllerView(currentNavigationController:UINavigationController,tags:[UIResrouceItemModel],selectionMode:ResourceExplorerSelectMode = .Multiple ,delegate:UIResourceExplorerDelegate! = nil)
    {
        let storyBoard = UIStoryboard(name: "Component", bundle: NSBundle.mainBundle())
        let collectionController = storyBoard.instantiateViewControllerWithIdentifier("tagCollectionViewController") as! UIFileCollectionController
        collectionController.items = tags
        collectionController.delegate = delegate
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
    
    @IBOutlet weak var tagNameLabel: UILabel!
    
}

class UIUserTagCollectionController: UIResourceExplorerController
{
    
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

