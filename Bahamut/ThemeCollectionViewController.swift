//
//  ThemeCollectionViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/13.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit


@objc
protocol ThemeCollectionViewControllerDelegate
{
    optional func themeCellDidClick(sender:ThemeCollectionViewController,cell:ThemeCollectionCell,indexPath:NSIndexPath)
}

class ThemeCollectionCell: UICollectionViewCell
{
    static let selectedMarkImage = UIImage.namedImageInSharelink("check")!
    static let normalMarkImage = UIImage.namedImageInSharelink("bullet-blue")!
    
    static let cellIdentifier = "themeCell"
    @IBOutlet weak var themeNameLabel: UILabel!
    @IBOutlet weak var cellStatusMarkView: UIImageView!{
        didSet{
            cellStatusMarkView.image = selected ? ThemeCollectionCell.selectedMarkImage : ThemeCollectionCell.normalMarkImage
        }
    }
    
    var indexPath:NSIndexPath!
    
    override var selected:Bool{
        didSet{
            if cellStatusMarkView != nil{
                cellStatusMarkView.image = selected ? ThemeCollectionCell.selectedMarkImage : ThemeCollectionCell.normalMarkImage
            }
        }
    }
}

class ThemeCollectionViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout
{
    private var reloadSelectionMarkMap = [String:Bool]()
    var themes:[SharelinkTheme] = [SharelinkTheme](){
        didSet{
            if collectionView != nil
            {
                collectionView?.reloadData()
            }
        }
    }
    
    var selectedIndexPaths:[NSIndexPath]{
        var result = [NSIndexPath]()
        for i in 0..<themes.count
        {
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            
            if let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? ThemeCollectionCell
            {
                if cell.selected
                {
                    result.append(indexPath)
                }
            }
        }
        return result
    }
    
    var selectedThemes:[SharelinkTheme]{
        
        var result = [SharelinkTheme]()
        for i in 0..<themes.count
        {
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            
            if let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? ThemeCollectionCell
            {
                if cell.selected
                {
                    result.append(themes[cell.indexPath.row])
                }
            }
        }
        return result
    }
    
    var delegate:ThemeCollectionViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.delegate = self
        collectionView?.reloadData()
    }
    
    func setCellSelectValue(index:NSIndexPath,selected:Bool) -> Bool
    {
        if let cell = collectionView?.cellForItemAtIndexPath(index) as? ThemeCollectionCell
        {
            cell.selected = selected
            return true
        }
        return false
    }
    
    func addThemes(themesModel:[SharelinkTheme],refreshCollection:Bool = true)
    {
        let indexPaths = themesModel.map{self.addTheme($0, refreshCollection: false)}.filter{$0 != nil}.map{$0!}
        if refreshCollection
        {
            collectionView?.reloadItemsAtIndexPaths(indexPaths)
        }
    }
    
    func addTheme(themeModel:SharelinkTheme,refreshCollection:Bool = true)->NSIndexPath?
    {
        let exists = themes.contains{ $0.getThemeString() == themeModel.getThemeString() }
        if exists
        {
            return nil
        }else
        {
            let indexPath = NSIndexPath(forRow: themes.count, inSection: 0)
            themes.append(themeModel)
            if refreshCollection
            {
                collectionView?.reloadItemsAtIndexPaths([indexPath])
            }
            return indexPath
        }
    }
    
    private func getIndexPathSelectionKey(indexPath:NSIndexPath) -> String
    {
        return "\(indexPath.section)_\(indexPath.row)"
    }
    
    func reloadCollection(selectedIndexPath:[NSIndexPath]! = nil)
    {
        if let paths = selectedIndexPath
        {
            for p in paths{
                reloadSelectionMarkMap[getIndexPathSelectionKey(p)] = true
            }
        }
        self.collectionView?.reloadData()
    }
    
    func removeTheme(indexPath:NSIndexPath)
    {
        themes.removeAtIndex(indexPath.row)
        collectionView?.reloadData()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThemeCollectionCell.cellIdentifier, forIndexPath: indexPath) as! ThemeCollectionCell
        let color = UIColor(hexString: themes[indexPath.row].tagColor)
        if let label = cell.themeNameLabel
        {
            label.font = themeNameLabelFont
            label.text = themes[indexPath.row].getShowName()
            label.textColor = color
        }
        
        cell.indexPath = indexPath
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self,action:#selector(ThemeCollectionViewController.tagDidTap(_:))))
        
        //Redraw
        let path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.BottomLeft , .TopLeft], cornerRadii: CGSizeMake(23.0, 23.0))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = cell.bounds
        maskLayer.path = path.CGPath
        cell.layer.mask = maskLayer
        cell.userInteractionEnabled = true
        cell.setNeedsLayout()
        cell.setNeedsDisplay()
        
        //Selection
        let key = getIndexPathSelectionKey(indexPath)
        if let flag = reloadSelectionMarkMap.removeValueForKey(key)
        {
            if flag
            {
                cell.selected = true
            }
        }
        return cell
    }
    
    func tagDidTap(aTap:UITapGestureRecognizer)
    {
        if let cell = aTap.view as? ThemeCollectionCell
        {
            let indexPath = cell.indexPath
            if let tapHandler = delegate.themeCellDidClick
            {
                tapHandler(self,cell: cell,indexPath: indexPath)
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.frame = view.superview!.bounds
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return themes.count
    }
    
    //MARK: layout
    
    let themeNameLabelFont = UIFont.systemFontOfSize(16.0)
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsMake(3, 3, 3, 3);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let label = UILabel()
        label.font = themeNameLabelFont
        label.text = themes[indexPath.row].getShowName()
        label.sizeToFit()
        return CGSizeMake(label.bounds.width + 23, label.bounds.height)
    }
    
    static func instanceFromStoryBoard() -> ThemeCollectionViewController
    {
        return instanceFromStoryBoard("Component", identifier: "tagCollectionViewController",bundle: Sharelink.mainBundle()) as! ThemeCollectionViewController
    }
}