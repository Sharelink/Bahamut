//
//  UITagCollectionViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/13.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class UITagCellModel
{
    var tagColor:String!
    var tagName:String!
}

protocol UITagCollectionViewControllerDelegate
{
    
}

class UITagCollectionViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout
{
    var tags:[UITagCellModel]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tags = [UITagCellModel]()
        let tag = UITagCellModel()
        tag.tagColor = UIColor.redColor().toHexString()
        tag.tagName = "hahahahah"
        tags.append(tag)
        
        let tag2 = UITagCellModel()
        tag2.tagColor = UIColor.redColor().toHexString()
        tag2.tagName = "hahah"
        tags.append(tag2)
        collectionView?.reloadData()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tagCell", forIndexPath: indexPath)
        let color = UIColor(hexString: tags[indexPath.row].tagColor)
        if let label = cell.viewWithTag(1) as? UILabel
        {
            label.text = tags[indexPath.row].tagName
            label.textColor = color
        }
        let path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.BottomLeft , .TopLeft], cornerRadii: CGSizeMake(23.0, 23.0))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = cell.bounds
        maskLayer.path = path.CGPath
        cell.layer.mask = maskLayer
        let maskBorderLayer = CAShapeLayer(layer: cell.layer)
        maskBorderLayer.path = maskLayer.path
        maskBorderLayer.fillColor = UIColor.clearColor().CGColor
        maskBorderLayer.strokeColor = color.CGColor
        maskBorderLayer.lineWidth = 2
        cell.layer.addSublayer(maskBorderLayer)
        
        cell.setNeedsLayout()
        cell.setNeedsDisplay()
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return tags.count
    }
    
    //MARK: layout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(7, 7, 7, 7);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let uifont = UIFont.systemFontOfSize(10.0)
        var size = NSString(string: tags[indexPath.row].tagName).sizeWithAttributes([NSFontAttributeName : uifont])
        size.width += 23.0
        size.height += 7.0
        return size
    }
    
    static func instanceFromStoryBoard() -> UITagCollectionViewController
    {
        return instanceFromStoryBoard("Component", identifier: "tagCollectionViewController") as! UITagCollectionViewController
    }
}