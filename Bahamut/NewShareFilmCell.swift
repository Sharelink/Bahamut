//
//  NewShareFilmCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MBProgressHUD

class NewShareFilmCell: NewShareCellBase,QupaiSDKDelegate,UIResourceExplorerDelegate,UIShareContentViewSetupDelegate
{
    static let thumbQuality:CGFloat = 0.5
    static let reuseableId = "NewShareFilmCell"
    @IBOutlet weak var shareContentContainer: UIShareContent!
    
    @IBOutlet weak var recordFilmBtn: UIButton!
    @IBOutlet weak var selectFilmBtn: UIButton!
    
    override func initCell() {
        recordFilmBtn.hidden = isReshare
        selectFilmBtn.hidden = isReshare
        shareContentContainer.setupContentViewDelegate = self
        refreshShareContent()
    }
    
    override func clear() {
        refreshShareContent()
    }
    
    @IBAction func selectFilm(sender: AnyObject) {
        let files = fileService.getFileModelsOfFileLocalStore(FileType.Video)
        fileService.showFileCollectionControllerView(self.rootController.navigationController!, files: files,selectionMode:.Single, delegate: self)
        MobClick.event("SelectVideoButton")
    }
    
    @IBAction func recordFilm(sender: AnyObject) {
        showQuPaiCamera()
        MobClick.event("RecordVideoButton")
    }
    
    //MARK: share content
    func setupContentView(contentView: UIView, share: ShareThing)
    {
        if let player = contentView as? ShareLinkFilmView
        {
            if isReshare
            {
                player.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Video)
            }else
            {
                player.fileFetcher = FilePathFileFetcher.shareInstance
            }
            player.playerController.fillMode = AVLayerVideoGravityResizeAspect
            player.autoLoad = true
        }
    }
    
    func refreshShareContent()
    {
        shareContentContainer.delegate = UIShareContentTypeDelegateGenerator.getDelegate(ShareThingType(rawValue: shareModel.shareType!)!)
        shareContentContainer.share = shareModel
        shareContentContainer.update()
    }
    
    
    //MARK: select film delegate
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel],sender: UIResourceExplorerController!) {
        if itemModels.count > 0
        {
            let fileModel = itemModels.first as! UIFileCollectionCellModel
            let filmModel = FilmModel()
            filmModel.film = fileModel.filePath
            filmModel.preview = ImageUtil.getVideoThumbImageBase64String(fileModel.filePath,compressionQuality: NewShareFilmCell.thumbQuality)
            self.shareContentContainer.share.shareContent = filmModel.toJsonString()
            self.shareContentContainer.update()
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        ShareLinkFilmView.showPlayer(sender, uri: fileModel.filePath, fileFetcer: FilePathFileFetcher.shareInstance)
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!) {
        let fileModels = itemModels as! [UIFileCollectionCellModel]
        var sum = 0
        for fileModel in fileModels
        {
            if fileModel.filePath == FilmModel(json: shareModel.shareContent).film
            {
                shareModel.shareContent = nil
                shareContentContainer.update()
            }
            do
            {
                try NSFileManager.defaultManager().removeItemAtPath(fileModel.filePath)
                sum++
            }catch let error as NSError{
                NSLog(error.description)
            }
        }
        self.rootController.showAlert("", msg: String(format:(NSLocalizedString("FILES_WAS_DELETED", comment: "%@ files deleted")), sum))
    }
    
    //MARK: set share video
    func setShareVideo(filePath:String)
    {
        let filmModel = FilmModel()
        filmModel.film = filePath
        filmModel.preview = ImageUtil.getVideoThumbImageBase64String(filePath,compressionQuality: NewShareFilmCell.thumbQuality)
        self.shareContentContainer.share.shareContent = filmModel.toJsonString()
        self.shareContentContainer.update()
    }
    
    //MARK: qupai
    func showQuPaiCamera()
    {
        if let qpController = QuPaiRecordCamera().getQuPaiController(self)
        {
            self.rootController.presentViewController(qpController, animated: true, completion: nil)
        }
    }
    
    func qupaiSDK(sdk: ALBBQuPaiPluginPluginServiceProtocol!, compeleteVideoPath videoPath: String!, thumbnailPath: String!)
    {
        self.rootController.dismissViewControllerAnimated(false, completion: nil)
        if videoPath != nil
        {
            if let newFilePath = saveVideo(videoPath)
            {
                setShareVideo(newFilePath)
            }
        }
        
    }
    
    //MARK: Save video
    func saveVideo(videoSourcePath:String) -> String?
    {
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if fileService.moveFileTo(videoSourcePath, destinationPath: newFilePath)
        {
            self.rootController.showCheckMark(NSLocalizedString("VIDEO_SAVED", comment: "Video Saved") )
            let size = PersistentManager.sharedInstance.fileSizeOf(newFilePath)
            print(size)
            return newFilePath
        }else
        {
            self.rootController.showAlert(NSLocalizedString("SAVE_VIDEO_FAILED", comment: "Save Video Failed"), msg: "")
            return nil
        }
    }
    
}
