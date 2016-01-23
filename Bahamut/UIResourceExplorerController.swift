//
//  UIVideoFileCollectionController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

//MARK: model
@objc
class UIResrouceItemModel : NSObject
{
    var cell:UIResourceItemCell!{
        didSet{
            cell.highlighted = selected
        }
    }
    var indexPath:NSIndexPath!
    var selected:Bool = false{
        didSet{
            if cell != nil{
                cell.highlighted = selected
            }
        }
    }
    
    var canEdit:Bool{
        return true
    }
    
    var editModeSelected:Bool =  false{
        didSet{
            if cell != nil{
                cell.highlighted = editModeSelected
            }
        }
    }
    
    func updateView()
    {
        if cell != nil
        {
            cell.update()
        }
    }
}

class UIResourceItemCell: UICollectionViewCell
{
    var model:UIResrouceItemModel!
    
    func update(){}
}

//MARK:Delegate
@objc
protocol UIResourceExplorerDelegate
{
    optional func resourceExplorerItemsSelected(itemModels:[UIResrouceItemModel] ,sender:UIResourceExplorerController!)
    optional func resourceExplorerAddItem(completedHandler:(itemModel:UIResrouceItemModel,indexPath:NSIndexPath) -> Void,sender:UIResourceExplorerController!)
    optional func resourceExplorerDeleteItem(itemModels:[UIResrouceItemModel],sender:UIResourceExplorerController!)
    optional func resourceExplorerOpenItem(itemModel:UIResrouceItemModel,sender:UIResourceExplorerController!)
    
}

enum ResourceExplorerSelectMode
{
    case Negative
    case Single
    case Multiple
}

//MARK: controller
class UIResourceExplorerController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    
    var delegate:UIResourceExplorerDelegate!
    
    func getCellReuseIdentifier() -> String{return "ResourceExplorerItemCell"}
    
    private(set) weak var collectionView: UICollectionView!{
        didSet{
            collectionView.delegate = self
            collectionView.dataSource = self //need to bind the data source and the delegate
            collectionView.allowsSelection = false
            collectionView.allowsMultipleSelection = false
        }
    }
    
    func getCollectionView() -> UICollectionView
    {
        fatalError("have to override this function")
    }
    
    var items:[[UIResrouceItemModel]]!{
        didSet{
            if collectionView != nil
            {
                collectionView.reloadData()
            }
        }
    }
    
    var selectionMode:ResourceExplorerSelectMode = ResourceExplorerSelectMode.Multiple{
        didSet{
            if collectionView != nil
            {
                collectionView.reloadData()
            }
        }
    }
    
    private func addItemCompletedHandler(itemModel:UIResrouceItemModel,indexPath:NSIndexPath)
    {
        items[indexPath.section].append(itemModel)
        collectionView.reloadData()
    }
    
    func addItem(sender: AnyObject) {
        if let addItemDelegate = delegate.resourceExplorerAddItem
        {
            addItemDelegate(addItemCompletedHandler,sender: self)
        }
    }
    
    func deleteItem(sender: AnyObject) {
        if let deleteDelegate = self.delegate.resourceExplorerDeleteItem
        {
            var willDeleteItems = [UIResrouceItemModel]()
            for item in items
            {
                willDeleteItems.appendContentsOf(item.filter{$0.editModeSelected})
            }
            deleteDelegate(willDeleteItems,sender: self)
        }
        for var i = 0 ;i < items.count; i++
        {
            items[i] = items[i].filter{ !$0.editModeSelected }
        }
        
    }
    
    func editItems(sender: AnyObject)
    {
        let btn = sender as! UIBarButtonItem
        editing = !editing
        if editing
        {
            btn.title = NSLocalizedString("FINISH", comment: "Finish")
            for item in items
            {
                for model in item
                {
                    model.editModeSelected = false
                }
            }
            navigationController?.setToolbarHidden(false, animated: true)
            
        }else
        {
            btn.title = NSLocalizedString("FINISH", comment: "Edit")
            for item in items
            {
                for model in item
                {
                    model.editModeSelected = false
                    let selected = model.selected
                    model.selected = selected
                }
                
            }
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView = getCollectionView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: collection delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.getCellReuseIdentifier(), forIndexPath: indexPath) as! UIResourceItemCell
        cell.model = items[indexPath.section][indexPath.row]
        cell.model.cell = cell
        cell.model.indexPath = indexPath
        
        let doubleClick = UITapGestureRecognizer(target: self, action: "openItem:")
        doubleClick.numberOfTapsRequired = 2
        let selectTap = UITapGestureRecognizer(target: self, action: "selectItem:")
        selectTap.requireGestureRecognizerToFail(doubleClick)
        cell.addGestureRecognizer(selectTap)
        cell.addGestureRecognizer(doubleClick)
        cell.update()
        return cell
    }
    
    //MARK: operate
    
    func selectItem(recognizer:UITapGestureRecognizer)->Void
    {
        let cell = recognizer.view as! UIResourceItemCell
        let model = cell.model
        if editing
        {
            if model.canEdit
            {
                model.editModeSelected = !model.editModeSelected
            }
        }else if selectionMode == .Negative
        {
            openItem(recognizer)
        }else if selectionMode == .Single
        {
            let selected = model.selected
            for item in items
            {
                for model in item
                {
                    model.selected = false
                }
            }
            model.selected = !selected
        }else if selectionMode == .Multiple
        {
            model.selected = !model.selected
        }
        
    }
    
    func notifyItemSelectState()
    {
        if let delegate = delegate?.resourceExplorerItemsSelected
        {
            var selectedItems = [UIResrouceItemModel]()
            for item in items
            {
                selectedItems.appendContentsOf(item.filter{$0.selected})
            }
            delegate(selectedItems,sender: self)
        }
    }
    
    func openItem(recognizer:UITapGestureRecognizer)->Void
    {
        if let openDelegate = delegate?.resourceExplorerOpenItem
        {
            let cell = recognizer.view as! UIResourceItemCell
            openDelegate(cell.model,sender: self)
        }
    }
}
