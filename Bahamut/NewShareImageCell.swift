//
//  NewShareImageCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/26.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import ImagePicker
import UIKit

class ShareImageContentModel: BahamutObject
{
    var thumbImgs:[String]!
    var imagesFileId:String!
}

class ShareImageHub: BahamutObject
{
    var imagesBase64:[String]!
}

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
class NewShareImageCell: ShareContentCellBase,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,ImagePickerDelegate,ProgressTaskDelegate
{
    static var uploadImageQuality:CGFloat = 0.5
    static var uploadImageWidth:CGFloat = 640
    static var thumbImageQuality:CGFloat = 0.3
    static var thumbImageSize = CGSizeMake(168, 168)
    static let maxImagePostCount = 9
    private var images = [UIImage]()
    static let AddImage = UIImage.namedImageInSharelink("add")!
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
        if rootController.isReshare
        {
            if let shareContent = rootController.passedShareModel?.shareContent
            {
                let imageContentModel = ShareImageContentModel(json:shareContent)
                let images = imageContentModel.thumbImgs.map{ImageUtil.getImageFromBase64String($0)}.filter{$0 != nil}.map{$0!}
                self.images = images
            }
        }
    }
    
    override func clear() {
        super.clear()
        self.images.removeAll()
        self.selectedStack = nil
        self.imageCollectionView.reloadData()
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        if images.count == 0
        {
            self.rootController.playToast("NO_IMAGE_SELECTED".localizedString())
            return false
        }else
        {
            postShare(baseShareModel, themes: themes)
            return true
        }
    }
    
    private func generateShareContent() -> (content:ShareImageContentModel,imagesHubFilePath:String)!
    {
        let contentModel = ShareImageContentModel()
        contentModel.thumbImgs = [String]()
        let imageHubFile = ShareImageHub()
        imageHubFile.imagesBase64 = [String]()
        let thumbSize = images.count < 3 ? CGSizeMake(NewShareImageCell.thumbImageSize.width * 2, NewShareImageCell.thumbImageSize.height * 2) : NewShareImageCell.thumbImageSize
        let thumbQuality = NewShareImageCell.thumbImageQuality
        for img in images
        {
            let imgString = img.scaleToWidthOf(NewShareImageCell.uploadImageWidth).generateImageDataOfQuality(NewShareImageCell.uploadImageQuality)?.base64UrlEncodedString() ?? ""
            imageHubFile.imagesBase64.append(imgString)
            let thumbImgString = img.scaleToWidthOf(thumbSize.width).generateImageDataOfQuality(thumbQuality)?.base64UrlEncodedString() ?? ""
            contentModel.thumbImgs.append(thumbImgString)
        }
        let imagesHubFilePath = fileService.createLocalStoreFileName(FileType.NoType)
        if PersistentFileHelper.storeFile(imageHubFile.toJsonString().toUTF8EncodingData(), filePath: imagesHubFilePath)
        {
            return (contentModel,imagesHubFilePath)
        }else
        {
            return nil
        }
    }
    
    //MARK: new share task entity
    class NewImageShareTask : BahamutObject
    {
        var id:String!
        var share:ShareThing!
        var shareThemes:[SharelinkTheme]!
        var sendFileKey:FileAccessInfo!
    }
    
    private func postShare(newShare:ShareThing,themes:[SharelinkTheme])
    {
        newShare.shareType = ShareThingType.shareImage.rawValue
        let phud = self.rootController.showActivityHudWithMessage(nil, message: "PREPARING_SHARE".localizedString())
        if let content = generateShareContent()
        {
            phud.hideAsync(true)
            let shud = self.rootController.showActivityHudWithMessage("",message:"SENDING_FILE".localizedString())
            self.fileService.sendFileToAliOSS(content.imagesHubFilePath, type: FileType.NoType) { (taskId, fileKey) -> Void in
                shud.hideAsync(true)
                ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
                if let fk = fileKey
                {
                    content.content.imagesFileId = fk.fileId
                    newShare.shareContent = content.content.toJsonString()
                    let newShareTask = NewImageShareTask()
                    newShareTask.id = taskId
                    newShareTask.shareThemes = themes
                    newShareTask.share = newShare
                    newShareTask.sendFileKey = fk
                    newShareTask.saveModel()
                }
            }
        }else{
            phud.hideAsync(true)
            self.rootController.playCrossMark("PREPARE_SHARE_ERROR".localizedString())
        }
        
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewImageShareTask.self, idValue: taskIdentifier)
        {
            self.shareService.postNewShare(task.share, tags: task.shareThemes ,callback: { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true){ (isSuc) -> Void in
                        if isSuc
                        {
                            NewImageShareTask.deleteObjectArray([task])
                        }
                    }
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewImageShareTask.self, idValue: taskIdentifier)
        {
            self.rootController.playToast("SEND_FILE_FAILED".localizedString())
            NewImageShareTask.deleteObjectArray([task])
        }
    }
    
    //MARK: actions
    
    //MARK: add image
    func addImage(_:UITapGestureRecognizer)
    {
        showImagePicker()
    }
    
    //MARK:
    
    private var imagePicker:ImagePickerController!{
        didSet{
            imagePicker.delegate = self
        }
    }
    
    private var selectedStack:ImageStack!
    
    func showImagePicker()
    {
        imagePicker = ImagePickerController()
        self.rootController.presentViewController(imagePicker, animated: true){
            if self.selectedStack != nil
            {
                self.imagePicker.stack.resetAssets(self.selectedStack.assets)
            }
        }
    }
    
    //MAARK: image picker delegate
    func wrapperDidPress(images: [UIImage]) {
    }
    
    func doneButtonDidPress(newImages: [UIImage]) {
        let mostImagesLimit = NewShareImageCell.maxImagePostCount
        if mostImagesLimit < newImages.count
        {
            let msgFormat = "ADD_IMAGE_LIMIT_AT_X".localizedString()
            let msg = String(format:msgFormat,"\(mostImagesLimit)")
            let alert = UIAlertController(title: msg, message: nil, preferredStyle: .Alert)
            alert.addAction(ALERT_ACTION_I_SEE)
            self.imagePicker.presentViewController(alert, animated: true, completion: nil)
            return
        }
        selectedStack = imagePicker.stack
        self.imagePicker.dismissViewControllerAnimated(true, completion: {
            self.images = newImages
            self.imageCollectionView.reloadData()
        })
    }
    
    func cancelButtonDidPress() {
        
    }
    
    //MAARK: image actions
    
    func tapImage(a:UITapGestureRecognizer)
    {
        if let cell = a.view as? NewShareImageCollectionViewCell
        {
            if let index = imageCollectionView.indexPathForCell(cell)
            {
                self.selectedStack.assets.removeAtIndex(index.row)
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
            return rootController.isReshare ? images.count : images.count + 1
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
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NewShareImageCell.addImage(_:))))
        }else
        {
            cell.imageView.image = images[indexPath.row]
            cell.imageView.layer.borderWidth = 1
            if !rootController.isReshare
            {
                let tapGes = UITapGestureRecognizer(target: self, action: #selector(NewShareImageCell.tapImage(_:)))
                let doubleTapGes = UITapGestureRecognizer(target: self, action: #selector(NewShareImageCell.doubleTapImage(_:)))
                doubleTapGes.numberOfTapsRequired = 2
                tapGes.requireGestureRecognizerToFail(doubleTapGes)
                cell.addGestureRecognizer(tapGes)
                cell.addGestureRecognizer(doubleTapGes)
            }
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