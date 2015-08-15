//
//  UIVideoFileCollectionController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class UIFileCollectionCell: UICollectionViewCell
{
    @IBOutlet weak var fileThumbImageView: UIImageView!
    
}

@objc
class UIFileCollectionCellModel : NSObject
{
    var fileType:FileType!
    var filePath:String!
    var thumbImage:UIImage!
}

@objc
protocol UIFileCollectionControllerDelegate
{
    optional func fileSelected(fileModel:UIFileCollectionCellModel, index:Int)
    optional func fileDeSelected(fileModel:UIFileCollectionCellModel, index:Int)
}

class UIFileCollectionController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource
{
    enum FileSelectMode
    {
        case None
        case SingleSelect
        case MultiSelect
    }
    
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.reloadData()
        }
    }
    var files:[UIFileCollectionCellModel]!{
        didSet{
            if collectionView != nil
            {
                collectionView.reloadData()
            }
        }
    }
    var selectedFiles:[UIFileCollectionCellModel]!
    var selectedMode:FileSelectMode = .None{
        didSet{
            collectionView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return selectedMode != .None
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier: String = "FileItemCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! UIFileCollectionCell
        cell.fileThumbImageView.image = files[indexPath.row].thumbImage
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
}
