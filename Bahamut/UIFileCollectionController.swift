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

class UIFileCollectionCell: UIResourceItemCell
{
    
    @IBOutlet weak var fileThumbImageView: UIImageView!
    
    override func update() {
        if model != nil
        {
            if let fileModel = model! as? UIFileCollectionCellModel
            {
                fileThumbImageView.image = fileModel.thumbImage
            }
        }
        
    }
}

//MARK: model
class UIFileCollectionCellModel : UIResrouceItemModel
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

//MARK: service extensino
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
    
    func showFileCollectionControllerView(currentNavigationController:UINavigationController,files:[UIFileCollectionCellModel],selectionMode:ResourceExplorerSelectMode = .Negative ,delegate:UIResourceExplorerDelegate! = nil)
    {
        let storyBoard = UIStoryboard(name: "Component", bundle: NSBundle.mainBundle())
        let fileCollectionController = storyBoard.instantiateViewControllerWithIdentifier("fileCollectionViewController") as! UIFileCollectionController
        fileCollectionController.items = files
        fileCollectionController.delegate = delegate
        fileCollectionController.selectionMode = selectionMode
        currentNavigationController.pushViewController(fileCollectionController, animated: true)
    }
}

//MARK: controller
class UIFileCollectionController: UIResourceExplorerController
{

    @IBOutlet weak var uiCollectionView: UICollectionView!
    
    override func getCollectionView() -> UICollectionView {
        return uiCollectionView
    }
    
    override func getCellReuseIdentifier() -> String {
        return "FileItemCell"
    }
    
    @IBAction func addFile(sender: AnyObject) {
        addItem(sender)
    }
    
    @IBAction func deleteFile(sender: AnyObject) {
        deleteItem(sender)
    }
    
    @IBAction func editFiles(sender: AnyObject)
    {
        editItems(sender)
    }
}
