//
//  UIVideoFileCollectionController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import PBJVision
import AVKit
import AVFoundation

//MARK: model
@objc
class UIResrouceItemModel : NSObject
{
    var selected:Bool = false
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
    optional func resourceExplorerItemSelected(itemModel:UIResrouceItemModel, index:Int ,sender:UIResourceExplorerController!)
    optional func resourceExplorerItemDeSelected(itemModel:UIResrouceItemModel, index:Int,sender:UIResourceExplorerController!)
    optional func resourceExplorerAddItem(completedHandler:(itemModel:UIResrouceItemModel) -> Void,sender:UIResourceExplorerController!)
    optional func resourceExplorerDeleteItem(itemModels:[UIResrouceItemModel],sender:UIResourceExplorerController!)
    optional func resourceExplorerOpenItem(itemModel:UIResrouceItemModel,sender:UIResourceExplorerController!)
    
}

public enum ResourceExplorerSelectMode
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
    
    private weak var collectionView: UICollectionView!{
        didSet{
            collectionView.delegate = self
            collectionView.dataSource = self //need to bind the data source and the delegate
            collectionView.allowsSelection = selectionMode != .Negative
            collectionView.allowsMultipleSelection = selectionMode == .Multiple
        }
    }
    
    func getCollectionView() -> UICollectionView
    {
        fatalError("have to override this function")
    }
    
    var items:[UIResrouceItemModel]!{
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
                collectionView.allowsSelection = selectionMode != .Negative
                collectionView.allowsMultipleSelection = selectionMode == .Multiple
                collectionView.reloadData()
            }
        }
    }
    
    private func addItemCompletedHandler(itemModel:UIResrouceItemModel)
    {
        items.append(itemModel)
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
            let willDeleteItems = items.filter{ $0.selected }
            deleteDelegate(willDeleteItems,sender: self)
        }
        items = items.filter{ !$0.selected }
    }
    
    func editItems(sender: AnyObject)
    {
        let btn = sender as! UIBarButtonItem
        if editing
        {
            btn.title = "Edit"
            collectionView.allowsSelection = selectionMode != .None
            collectionView.allowsMultipleSelection = selectionMode == .Multiple
            navigationController?.setToolbarHidden(true, animated: true)
            
        }else
        {
            btn.title = "Finish"
            collectionView.allowsSelection = true
            collectionView.allowsMultipleSelection = true
            navigationController?.setToolbarHidden(false, animated: true)
        }
        editing = !editing
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView = getCollectionView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initAddItemButton()
    }
    
    private func initAddItemButton()
    {
        if let buttons = navigationItem.rightBarButtonItems
        {
            var i = 0
            for btn in buttons
            {
                if btn.tag == 0
                {
                    if nil == delegate?.resourceExplorerAddItem
                    {
                        navigationItem.rightBarButtonItems?.removeAtIndex(i)
                        return
                    }
                }
                i++
            }
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(64, 64)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(4)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.getCellReuseIdentifier(), forIndexPath: indexPath) as! UIResourceItemCell
        cell.model = items[indexPath.row]
        
        //MARK: NOTE: stupid bug,use seleted = true,in the view deselect operate will not perform,use hightlingted only click twice can deselete the cell
        cell.highlighted  = cell.model.selected
        
        let doubleClick = UITapGestureRecognizer(target: self, action: "openItem:")
        doubleClick.numberOfTapsRequired = 2
        cell.addGestureRecognizer(doubleClick)
        cell.update()
        return cell
    }
    
    func openItem(recognizer:UITapGestureRecognizer)->Void
    {
        if let openDelegate = delegate?.resourceExplorerOpenItem
        {
            let cell = recognizer.view as! UIResourceItemCell
            openDelegate(cell.model,sender: self)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        items[indexPath.row].selected = false
        if !editing
        {
            if let delegate = delegate?.resourceExplorerItemDeSelected
            {
                delegate(items[indexPath.row] ,index: indexPath.row,sender: self)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        items[indexPath.row].selected = true
        if !editing
        {
            if let delegate = delegate?.resourceExplorerItemSelected
            {
                delegate(items[indexPath.row] ,index: indexPath.row,sender: self)
            }
        }
    }
}
