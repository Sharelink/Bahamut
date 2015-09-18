//
//  UITagCollectionViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/13.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

@objc
protocol UITagCollectionViewControllerDelegate
{
    optional func tagDidTap(sender:UITagCollectionViewController,indexPath:NSIndexPath)
}

class TagCollectionCell: UICollectionViewCell
{
    static let cellIdentifier = "tagCell"
    @IBOutlet weak var tagNameLabel: UILabel!
    var indexPath:NSIndexPath!
}

class UITagCollectionViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout
{
    var tags:[SharelinkTag]!{
        didSet{
            if collectionView != nil
            {
                collectionView?.reloadData()
            }
        }
        
    }
    
    var delegate:UITagCollectionViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.delegate = self
        collectionView?.reloadData()
    }
    
    func addTag(tagModel:SharelinkTag)->Bool
    {
        if tags == nil
        {
            tags = [SharelinkTag]()
        }
        let exists = tags.contains{ $0.getTagString() == tagModel.getTagString() }
        if exists
        {
            return false
        }else
        {
            tags.append(tagModel)
            collectionView?.reloadData()
            return true
        }
    }
    
    func removeTag(indexPath:NSIndexPath)
    {
        tags.removeAtIndex(indexPath.row)
        collectionView?.reloadData()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tagCell", forIndexPath: indexPath) as! TagCollectionCell
        let color = UIColor(hexString: tags[indexPath.row].tagColor)
        if let label = cell.tagNameLabel
        {
            label.font = tagNameLabelFont
            label.text = tags[indexPath.row].tagName
            label.textColor = color
        }
        
        cell.indexPath = indexPath
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self,action:"tagDidTap:"))
        
        //Redraw
        let path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.BottomLeft , .TopLeft], cornerRadii: CGSizeMake(23.0, 23.0))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = cell.bounds
        maskLayer.path = path.CGPath
        cell.layer.mask = maskLayer
        cell.userInteractionEnabled = true
        cell.setNeedsLayout()
        cell.setNeedsDisplay()
        return cell
    }
    
    func tagDidTap(aTap:UITapGestureRecognizer)
    {
        if let cell = aTap.view as? TagCollectionCell
        {
            let indexPath = cell.indexPath
            if let tapHandler = delegate.tagDidTap
            {
                tapHandler(self, indexPath: indexPath)
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if tags == nil
        {
            return 0
        }
        return tags.count
    }
    
    //MARK: layout
    
    let tagNameLabelFont = UIFont.systemFontOfSize(13.0)
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let label = UILabel()
        label.font = tagNameLabelFont
        label.text = tags[indexPath.row].tagName
        label.sizeToFit()
        var size = label.bounds.size
        size.width += 17
        return size
    }
    
    static func instanceFromStoryBoard() -> UITagCollectionViewController
    {
        return instanceFromStoryBoard("Component", identifier: "tagCollectionViewController") as! UITagCollectionViewController
    }
}