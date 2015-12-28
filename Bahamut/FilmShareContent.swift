//
//  FilmShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import EVReflection

class FilmModel : EVObject
{
    var film:String!
    var preview:String!
}

class FilmContent: UIShareContentDelegate
{
    func initContent(shareCell: UIShareThing, share: ShareThing) {
        
    }
    
    func refresh(sender: UIShareContent, share: ShareThing?)
    {
        let mediaPlayer = sender.contentView as! ShareLinkFilmView
        mediaPlayer.filePath = nil
        if let json = share?.shareContent
        {
            let fm = FilmModel(json: json)
            if let preview = fm.preview
            {
                if let thumb = ImageUtil.getImageFromBase64String(preview)
                {
                    mediaPlayer.setThumb(thumb)
                }
            }
            
            if let film = fm.film
            {
                mediaPlayer.filePath = film
            }
        }
        mediaPlayer.refreshUI()
    }
    
    func getContentFrame(sender: UIShareThing, share: ShareThing?) -> CGRect {
        return CGRectMake(0,0,148,148)
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?)-> UIView
    {
        let player = ShareLinkFilmView(frame: CGRectMake(0,0,148,148))
        player.autoLoad = false
        player.autoPlay = true
        player.playerController.fillMode = AVLayerVideoGravityResizeAspect
        player.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(.Video)
        return player
    }
}