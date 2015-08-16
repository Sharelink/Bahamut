//
//  UIVideoFileCollectionController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import PBJVision
import AVKit
import AVFoundation

class UIFileCollectionCell: UICollectionViewCell
{
    @IBOutlet weak var fileThumbImageView: UIImageView!
    
}

@objc
class UIFileCollectionCellModel : NSObject
{
    var fileType:FileType = FileType.Raw
    var filePath:String!
    private(set) lazy var thumbImage:UIImage! = {
        if self.fileType == FileType.Video
        {
            return ImageUtil.getVideoThumbImage(self.filePath)
        }else if self.fileType == FileType.Text
        {
            return ImageUtil.getTextFileIconImage()
        }else if self.fileType == FileType.Sound
        {
            return ImageUtil.getSountIconImage()
        }else if self.fileType == FileType.Image
        {
            return ImageUtil.getImageThumbImage(self.filePath)
        }
        return UIImage(named: "file")
    }()
}

@objc
protocol UIFileCollectionControllerDelegate
{
    optional func fileSelected(fileModel:UIFileCollectionCellModel, index:Int ,sender:UIFileCollectionController!)
    optional func fileDeSelected(fileModel:UIFileCollectionCellModel, index:Int,sender:UIFileCollectionController!)
    optional func addFile(completedHandler:(fileModel:UIFileCollectionCellModel) -> Void,sender:UIFileCollectionController!)
}

extension FileService
{
    func getFileModelsOfFileLocalStore(fileType:FileType ) -> [UIFileCollectionCellModel]
    {
        return self.getLocalStoreDirFiles(fileType).map { (filePath) -> UIFileCollectionCellModel in
            let model = UIFileCollectionCellModel()
            model.filePath = filePath
            model.fileType = fileType
            return model
        }
    }
    
    func showFileCollectionControllerView(currentNavigationController:UINavigationController,files:[UIFileCollectionCellModel],delegate:UIFileCollectionControllerDelegate!)
    {
        let storyBoard = UIStoryboard(name: "Component", bundle: NSBundle.mainBundle())
        let fileCollectionController = storyBoard.instantiateViewControllerWithIdentifier("fileCollectionViewController") as! UIFileCollectionController
        fileCollectionController.files = files
        fileCollectionController.delegate = delegate
        currentNavigationController.pushViewController(fileCollectionController, animated: true)
    }
}

class UIFileCollectionController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource
{
    enum FileSelectMode
    {
        case None
        case SingleSelect
        case MultiSelect
    }
    var delegate:UIFileCollectionControllerDelegate!
    
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.reloadData()
            collectionView.delegate = self
            collectionView.dataSource = self //need to bind the data source and the delegate
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
    
    @IBAction func addFile(sender: AnyObject) {
        if let addFileDelegate = delegate.addFile
        {
            addFileDelegate(addFileCompletedHandler,sender: self)
        }
    }
    
    private func addFileCompletedHandler(fileModel:UIFileCollectionCellModel)
    {
        files.append(fileModel)
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initAddFileButton()
    }
    
    private func initAddFileButton()
    {
        if let buttons = navigationItem.rightBarButtonItems
        {
            var i = 0
            for btn in buttons
            {
                if btn.tag == 0
                {
                    if nil == delegate.addFile
                    {
                        navigationItem.rightBarButtonItems?.removeAtIndex(i)
                        return
                    }
                }
                i++
            }
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
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let delegate = delegate.fileSelected
        {
            delegate(files[indexPath.row] ,index: indexPath.row,sender: self)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let delegate = delegate.fileDeSelected
        {
            delegate(files[indexPath.row] ,index: indexPath.row,sender: self)
        }
    }
}
