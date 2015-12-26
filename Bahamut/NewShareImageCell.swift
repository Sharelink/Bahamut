//
//  NewShareImageCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import ChatFramework

//MARK:NewShareImageCollectionViewCell
class NewShareImageCollectionViewCell: UICollectionViewCell
{
    static let reuseId = "NewShareImageCollectionViewCell"
    @IBOutlet weak var imageView: UIImageView!{
        didSet{
            imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
            imageView.contentMode = .ScaleAspectFill
        }
    }
}

//MARK: NewShareImageCell
class NewShareImageCell: ShareContentCellBase,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    static let maxImagePostCount = 7
    private var images = [UIImage]()
    static let AddImage = UIImage(named: "add")!
    @IBOutlet weak var imageCollectionView: UICollectionView!{
        didSet{
            imageCollectionView.dataSource = self
            imageCollectionView.delegate = self
            imageCollectionView.backgroundColor = UIColor.whiteColor()
        }
    }
    static let reuseableId = "NewShareImageCell"
    
    override func getCellHeight() -> CGFloat {
        return 49 + imageCollectionView.contentSize.height
    }
    
    override func initCell() {
        super.initCell()
        if self.imagePickerController == nil
        {
            self.imagePickerController = UIImagePickerController()
        }
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        return true
    }
    //MARK: actions
    
    //MARK: add image
    func addImage(_:UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("TAKE_NEW_PHOTO", comment: "Take A New Photo"), style: .Destructive) { _ in
            self.newPictureWithCamera()
            })
        alert.addAction(UIAlertAction(title:NSLocalizedString("SELECT_PHOTO", comment: "Select A Photo From Album"), style: .Destructive) { _ in
            self.selectPictureFromAlbum()
            })
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel){ _ in})
        rootController.showAlert(alert)
    }
    
    //MARK:
    
    private var imagePickerController:UIImagePickerController!{
        didSet{
            imagePickerController.delegate = self
        }
    }
    
    func newPictureWithCamera()
    {
        imagePickerController.sourceType = .Camera
        imagePickerController.allowsEditing = false
        rootController.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func selectPictureFromAlbum()
    {
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        rootController.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    //MARK: image delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePickerController.dismissViewControllerAnimated(true){
            self.images.append(image)
            self.imageCollectionView.reloadData()
        }
    }
    
    func tapImage(a:UITapGestureRecognizer)
    {
        if let cell = a.view as? NewShareImageCollectionViewCell
        {
            if let index = imageCollectionView.indexPathForCell(cell)
            {
                self.images.removeAtIndex(index.row)
                self.imageCollectionView.reloadData()
            }
        }
    }
    
    func doubleTapImage(a:UITapGestureRecognizer)
    {
        if let cell = a.view as? NewShareImageCollectionViewCell
        {
            UUImageAvatarBrowser.showImage(cell.imageView)
        }
    }
    
    
    //MARK: collection view delegate
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if images.count < NewShareImageCell.maxImagePostCount
        {
            return images.count + 1
        }
        return NewShareImageCell.maxImagePostCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NewShareImageCollectionViewCell.reuseId, forIndexPath: indexPath) as! NewShareImageCollectionViewCell
        cell.gestureRecognizers?.removeAll()
        if images.count == indexPath.row
        {
            cell.imageView.image = NewShareImageCell.AddImage
            cell.imageView.layer.borderWidth = 0
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "addImage:"))
        }else
        {
            cell.imageView.image = images[indexPath.row]
            cell.imageView.layer.borderWidth = 1
            let tapGes = UITapGestureRecognizer(target: self, action: "tapImage:")
            let doubleTapGes = UITapGestureRecognizer(target: self, action: "doubleTapImage:")
            doubleTapGes.numberOfTapsRequired = 2
            tapGes.requireGestureRecognizerToFail(doubleTapGes)
            cell.addGestureRecognizer(tapGes)
            cell.addGestureRecognizer(doubleTapGes)
        }
        //resize the share content size
        rootController.refreshContentCellHeight()
        return cell
    }
    
    //MARK: collection view flowout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(67, 67)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 7
    }
    
}