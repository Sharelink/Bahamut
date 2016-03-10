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
    static let thumbQuality:CGFloat = 0.3
    static let reuseableId = "NewShareFilmCell"
    
    override func getCellHeight() -> CGFloat {
        return 211
    }
    
    private let filmModel = FilmModel()
    private var filmPlayer:ShareLinkFilmView!
    @IBOutlet weak var shareContentContainer: UIView!{
        didSet{
            shareContentContainer.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var recordFilmBtn: UIButton!
    @IBOutlet weak var selectFilmBtn: UIButton!
    
    override func initCell() {
        recordFilmBtn.hidden = isReshare || Sharelink.isSDKVersion
        selectFilmBtn.hidden = isReshare
        initFilmPlayer()
    }
    
    private func initFilmPlayer()
    {
        if filmPlayer == nil{
            filmPlayer = ShareLinkFilmView()
            filmPlayer.playerController.fillMode = AVLayerVideoGravityResizeAspect
            filmPlayer.autoLoad = true
            filmPlayer.layer.cornerRadius = 7
            shareContentContainer.addSubview(filmPlayer)
        }
        if let model = rootController.passedShareModel
        {
            let fm = FilmModel(json: model.shareContent)
            self.filmModel.film = fm.film
            self.filmModel.preview = fm.preview
        }
        if rootController.isReshare{
            filmPlayer.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Video)
        }else{
            filmPlayer.fileFetcher = FilePathFileFetcher.shareInstance
        }
        filmPlayer.filePath = filmModel.film
    }
    
    override func clear() {
        filmPlayer.filePath = nil
    }
    
    @IBAction func selectFilm(sender: AnyObject) {
        if let btn = sender as? UIView
        {
            btn.animationMaxToMin(0.1, maxScale: 1.1, completion: { () -> Void in
                let files = self.fileService.getFileModelsOfFileLocalStore(FileType.Video)
                self.fileService.showFileCollectionControllerView(self.rootController.navigationController!, files: files,selectionMode:.Single, delegate: self,title:"SELECT_FILM".localizedString())
            })
            MobClick.event("SelectVideoButton")
        }
    }
    
    @IBAction func recordFilm(sender: AnyObject) {
        #if APP_VERSION
            if let btn = sender as? UIView
            {
                btn.animationMaxToMin(0.1, maxScale: 1.1, completion: { () -> Void in
                    self.showQuPaiCamera()
                })
            }
            MobClick.event("RecordVideoButton")
        #endif
    }
    
    //MARK: select film delegate
    
    func resourceExplorerItemsSelected(itemModels: [UIResrouceItemModel],sender: UIResourceExplorerController!) {
        if itemModels.count > 0
        {
            let fileModel = itemModels.first as! UIFileCollectionCellModel
            filmModel.film = fileModel.filePath
            filmModel.preview = generatePreview(fileModel.filePath)
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
        self.rootController.showAlert("", msg: String(format:("FILES_WAS_DELETED".localizedString()), sum))
    }
    
    //MARK: generate preview
    private func generatePreview(filePath:String) -> String?
    {
        if let thumbImage = ImageUtil.generateThumb(filePath)
        {
            let thumbString = thumbImage.scaleToSize(CGSize(width: 168, height: 168)).generateImageDataOfQuality(NewShareFilmCell.thumbQuality)?.base64UrlEncodedString()
            return thumbString
        }
        return nil
    }
    
    #if APP_VERSION
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
                filmModel.preview = generatePreview(newFilePath)
                filmPlayer.filePath = filmModel.film
            }
        }
        
    }
    #endif
    
    //MARK: Save video
    func saveVideo(videoSourcePath:String) -> String?
    {
        let newFilePath = fileService.createLocalStoreFileName(FileType.Video)
        if PersistentFileHelper.moveFile(videoSourcePath, destinationPath: newFilePath)
        {
            self.rootController.playToast("VIDEO_SAVED".localizedString())
            return newFilePath
        }else
        {
            self.rootController.showAlert("SAVE_VIDEO_FAILED".localizedString(), msg: "")
            return nil
        }
    }
    
    //Post Share
    
    //MARK: new share task entity
    class NewFilmShareTask : BahamutObject
    {
        var id:String!
        var share:ShareThing!
        var shareThemes:[SharelinkTheme]!
        var sendFileKey:FileAccessInfo!
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        if String.isNullOrWhiteSpace(filmModel.film)
        {
            self.rootController.playToast("NO_FILM_SELECTED".localizedString())
            return false
        }else
        {
            postShare(baseShareModel, themes: themes)
            return true
        }
    }
    
    private func postShare(newShare:ShareThing,themes:[SharelinkTheme])
    {
        newShare.shareType = ShareThingType.shareFilm.rawValue
        let newFilmModel = FilmModel(json: self.filmModel.toJsonString())
        let hud = self.rootController.showActivityHudWithMessage("",message: "SENDING_FILE".localizedString())
        self.fileService.sendFileToAliOSS(newFilmModel.film, type: FileType.Video) { (taskId, fileKey) -> Void in
            hud.hideAsync(true)
            ProgressTaskWatcher.sharedInstance.addTaskObserver(taskId, delegate: self)
            if let fk = fileKey
            {
                newFilmModel.film = fk.fileId
                newShare.shareContent = newFilmModel.toJsonString()
                let newShareTask = NewFilmShareTask()
                newShareTask.id = taskId
                newShareTask.shareThemes = themes
                newShareTask.share = newShare
                newShareTask.sendFileKey = fk
                newShareTask.saveModel()
            }
        }
    }
    
    func taskCompleted(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewFilmShareTask.self, idValue: taskIdentifier)
        {
            self.shareService.postNewShare(task.share, tags: task.shareThemes ,callback: { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true){ (isSuc) -> Void in
                        if isSuc
                        {
                            NewFilmShareTask.deleteObjectArray([task])
                        }
                    }
                }
            })
        }
    }
    
    func taskFailed(taskIdentifier: String, result: AnyObject!) {
        if let task = PersistentManager.sharedInstance.getModel(NewFilmShareTask.self, idValue: taskIdentifier)
        {
            self.rootController.playToast("SEND_FILE_FAILED".localizedString())
            NewFilmShareTask.deleteObjectArray([task])
        }
    }
    
}
