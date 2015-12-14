//
//  FilmShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import EVReflection

class FilmModel : EVObject
{
    var film:String!
    var preview:String!
}

class FilmContent: UIShareContentDelegate
{
    func refresh(sender: UIShareContent, share: ShareThing?)
    {
        let mediaPlayer = sender.contentView as! ShareLinkFilmView
        mediaPlayer.filePath = nil
        if let json = share?.shareContent
        {
            let fm = FilmModel(json: json)
            if let preview = fm.preview
            {
                if let thumb = ImageUtil.getThumbImageFromBase64String(preview)
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
    
    func getContentView(sender: UIShareContent, share: ShareThing?)-> UIView
    {
        let player = ShareLinkFilmView(frame: sender.bounds)
        return player
    }
}