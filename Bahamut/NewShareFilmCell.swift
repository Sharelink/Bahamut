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

class NewShareFilmCell: ShareContentCellBase,QupaiSDKDelegate,UIResourceExplorerDelegate,ProgressTaskDelegate
{
    static let thumbQuality:CGFloat = 0.5
    static let reuseableId = "NewShareFilmCell"
    
    override func getCellHeight() -> CGFloat {
        return 211
    }
    
    private let filmModel = FilmModel()
    private var filmPlayer:ShareLinkFilmView!
    @IBOutlet weak var shareContentContainer: UIView!
    @IBOutlet weak var recordFilmBtn: UIButton!
    @IBOutlet weak var selectFilmBtn: UIButton!
    
    override func initCell() {
        recordFilmBtn.hidden = isReshare
        selectFilmBtn.hidden = isReshare
        initFilmPlayer()
    }
    
    private func initFilmPlayer()
    {
        if filmPlayer == nil{
            filmPlayer = ShareLinkFilmView()
            filmPlayer.playerController.fillMode = AVLayerVideoGravityResizeAspect
            filmPlayer.autoLoad = true
            shareContentContainer.addSubview(filmPlayer)
        }
        if isReshare
        {
            let fm = FilmModel(json: rootController.reShareModel.shareContent)
            self.filmModel.film = fm.film
            self.filmModel.preview = fm.preview
            filmPlayer.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Video)
        }else
        {
            filmPlayer.fileFetcher = FilePathFileFetcher.shareInstance
        }
        filmPlayer.filePath = filmModel.film
    }
    
    override func clear() {
        filmPlayer.filePath = nil
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
    
    //MARK: select film delegate
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel],sender: UIResourceExplorerController!) {
        if itemModels.count > 0
        {
            let fileModel = itemModels.first as! UIFileCollectionCellModel
            filmModel.film = fileModel.filePath
            filmModel.preview = ImageUtil.getVideoThumbImageBase64String(fileModel.filePath,compressionQuality: NewShareFilmCell.thumbQuality)
            filmPlayer.filePath = filmModel.film
        }
    }
    
    func resourceExplorerOpenItem(itemModel: UIResrouceItemModel, sender: UIResourceExplorerController!) {
        let fileModel = itemModel as! UIFileCollectionCellModel
        ShareLinkFilmView.showPlayer(sender, uri: fileModel.filePath, fileFetcer: FilePathFileFetcher.shareInstance)
    }
    
    func resourceExplorerDeleteItem(itemModels: [UIResrouceItemModel], sender: UIResourceExplorerController!) {
        let fileModels = itemModels as! [UIFileCollectionCellModel]
        var sum = 0
        for fm in fileModels
        {
            if fm.filePath == filmModel.film
            {
                filmPlayer.filePath = nil
            }
            do
            {
                try NSFileManager.defaultManager().removeItemAtPath(fm.filePath)
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
                filmModel.film = newFilePath
                filmModel.preview = ImageUtil.getVideoThumbImageBase64String(newFilePath,compressionQuality: NewShareFilmCell.thumbQuality)
                filmPlayer.filePath = filmModel.film
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
        if String.isNullOrWhiteSpace(filmModel.film)
        {
            self.rootController.showToast(NSLocalizedString("NO_FILM_SELECTED", comment: ""))
            return false
        }else
        {
            postShare(baseShareModel, tags: themes)
            return true
        }
    }
    
    private func postShare(newShare:ShareThing,tags:[SharelinkTheme])
    {
        newShare.shareType = ShareThingType.shareFilm.rawValue
        let newFilmModel = FilmModel(json: self.filmModel.toJsonString())
        self.rootController.makeToastActivityWithMessage("",message: NSLocalizedString("SENDING_FILM", comment: "Sending Film"))
        self.fileService.sendFileToAliOSS(newFilmModel.film, type: FileType.Video) { (taskId, fileKey) -> Void in
            self.rootController.hideToastActivity()
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
            if let fk = fileKey
            {
                newFilmModel.film = fk.fileId
                newShare.shareContent = newFilmModel.toJsonString()
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
