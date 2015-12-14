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

class NewShareFilmCell: ShareContentCellBase,QupaiSDKDelegate,UIResourceExplorerDelegate,UIShareContentViewSetupDelegate,ProgressTaskDelegate
{
    static let thumbQuality:CGFloat = 0.5
    static let reuseableId = "NewShareFilmCell"
    
    override func getCellHeight() -> CGFloat {
        return 211
    }
    
    @IBOutlet weak var shareContentContainer: UIShareContent!
    
    @IBOutlet weak var recordFilmBtn: UIButton!
    @IBOutlet weak var selectFilmBtn: UIButton!
    
    
    override func initCell() {
        recordFilmBtn.hidden = isReshare
        selectFilmBtn.hidden = isReshare
        shareContentContainer.setupContentViewDelegate = self
        resetShareContent()
    }
    
    override func clear() {
        resetShareContent()
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
    
    private func resetShareContent()
    {
        shareContentContainer.delegate = UIShareContentTypeDelegateGenerator.getDelegate(ShareThingType.shareFilm)
        shareContentContainer.share = isReshare ? rootController.reShareModel : ShareThing()
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
            if fileModel.filePath == FilmModel(json: shareContentContainer.share.shareContent).film
            {
                shareContentContainer.share.shareContent = nil
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
                let filmModel = FilmModel()
                filmModel.film = newFilePath
                filmModel.preview = ImageUtil.getVideoThumbImageBase64String(newFilePath,compressionQuality: NewShareFilmCell.thumbQuality)
                self.shareContentContainer.share.shareContent = filmModel.toJsonString()
                self.shareContentContainer.update()
            }
        }
        
    }
    
    //MARK: Save video
    func saveVideo(videoSourcePath:String) -> String?
    {
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if PersistentFileHelper.moveFile(videoSourcePath, destinationPath: newFilePath)
        {
            self.rootController.showToast(NSLocalizedString("VIDEO_SAVED", comment: "Video Saved") )
            return newFilePath
        }else
        {
            self.rootController.showAlert(NSLocalizedString("SAVE_VIDEO_FAILED", comment: "Save Video Failed"), msg: "")
            return nil
        }
    }
    
    //Post Share
    
    //MARK: new share task entity
    class NewFilmShareTask : BahamutObject
    {
        var id:String!
        var share:ShareThing!
        var shareTags:[SharelinkTheme]!
        var sendFileKey:FileAccessInfo!
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        if String.isNullOrWhiteSpace(self.shareContentContainer.share.shareContent)
        {
            self.rootController.showToast(NSLocalizedString("NO_FILM_SELECTED", comment: ""))
            return false
        }else
        {
            baseShareModel.shareContent = self.shareContentContainer.share.shareContent
            baseShareModel.shareType = ShareThingType.shareFilm.rawValue
            postShare(baseShareModel, tags: themes)
            return true
        }
    }
    
    private func postShare(newShare:ShareThing,tags:[SharelinkTheme])
    {
        let filmModel = FilmModel(json: newShare.shareContent)
        self.rootController.makeToastActivityWithMessage("",message: NSLocalizedString("SENDING_FILM", comment: "Sending Film"))
        self.fileService.sendFileToAliOSS(filmModel.film, type: FileType.Video) { (taskId, fileKey) -> Void in
            self.rootController.hideToastActivity()
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
            if let fk = fileKey
            {
                filmModel.film = fk.fileId
                newShare.shareContent = filmModel.toJsonString()
                let newShareTask = NewFilmShareTask()
                newShareTask.id = taskId
                newShareTask.shareTags = tags
                newShareTask.share = newShare
                newShareTask.sendFileKey = fk
                newShareTask.saveModel()
            }
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewFilmShareTask.self, idValue: taskIdentifier)
        {
            self.shareService.postNewShare(task.share, tags: task.shareTags ,callback: { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true){ (isSuc) -> Void in
                        if isSuc
                        {
                            self.rootController.showCheckMark(NSLocalizedString("POST_SHARE_SUC", comment: "Post Share Success"))
                            NewFilmShareTask.deleteObjectArray([task])
                        }else
                        {
                            self.rootController.showCrossMark(NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
                        }
                    }
                }else
                {
                    self.rootController.showCrossMark(NSLocalizedString("POST_SHARE_FAILED", comment: "Post Share Error"))
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewFilmShareTask.self, idValue: taskIdentifier)
        {
            self.rootController.showToast( NSLocalizedString("SEND_FILM_FAILED", comment: "Send File Failed"))
            NewFilmShareTask.deleteObjectArray([task])
        }
    }
    
}
