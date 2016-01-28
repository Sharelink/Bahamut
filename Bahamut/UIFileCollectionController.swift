//
//  UIVideoFileCollectionController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/15.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
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
        var img:UIImage? = nil
        if self.fileType == FileType.Video
        {
            img = ImageUtil.getVideoThumbImage(self.filePath)
        }else if self.fileType == FileType.Text
        {
            img = UIImage.namedImageInSharelink("text_file")
        }else if self.fileType == FileType.Sound
        {
            img = UIImage.namedImageInSharelink("music")
        }else if self.fileType == FileType.Image
        {
            img = ImageUtil.getImageThumbImage(self.filePath)
        }
        if let res = img
        {
            return res
        }
        return UIImage.namedImageInSharelink( "file")
    }()
}

//MARK: service extensino
extension FileService
{
    func getFileModelsOfFileLocalStore(fileType:FileType,selected:Bool = false ) -> [UIFileCollectionCellModel]
    {
        return self.getLocalStoreDirFiles(fileType).map { (filePath) -> UIFileCollectionCellModel in
            let model = UIFileCollectionCellModel()
            model.selected = selected
            model.filePath = filePath
            model.fileType = fileType
            return model
        }
    }
    
    func showFileCollectionControllerView(currentNavigationController:UINavigationController,files:[UIFileCollectionCellModel],title:String? = nil,selectionMode:ResourceExplorerSelectMode = .Negative ,delegate:UIResourceExplorerDelegate! = nil)
    {
        let fileCollectionController = UIFileCollectionController.instanceFromStoryBoard()
        fileCollectionController.selectionMode = selectionMode
        fileCollectionController.items = [files]
        fileCollectionController.delegate = delegate
        fileCollectionController.title = title
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return CGSizeMake(64, 64)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(4)
    }
    
    override var delegate:UIResourceExplorerDelegate!{
        didSet{
            if delegate == nil || self.delegate.resourceExplorerAddItem == nil{
                self.navigationItem.rightBarButtonItems?.removeAtIndex(1)
            }
        }
    }
    
    @IBAction func ok(sender: AnyObject)
    {
        notifyItemSelectState()
        self.navigationController?.popViewControllerAnimated(true)
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
    
    static func instanceFromStoryBoard() -> UIFileCollectionController
    {
        return instanceFromStoryBoard("Component", identifier: "fileCollectionViewController",bundle: Sharelink.mainBundle()) as! UIFileCollectionController
    }
}
