//
//  UIShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import AVFoundation
import SharelinkSDK
import EVReflection

protocol UIShareContentDelegate
{
    func refresh(sender:UIShareContent,share:ShareThing?)
    func getContentView(sender: UIShareContent, share: ShareThing?) -> UIView
    
}

class UIShareContentTypeDelegateGenerator
{
    static func getDelegate(shareType:ShareThingType) -> UIShareContentDelegate!
    {
        return getDelegate(shareType.rawValue)
    }
    
    static func getDelegate(shareType:String) -> UIShareContentDelegate!
    {
        switch(shareType)
        {
            case ShareThingType.shareFilm.rawValue : return FilmContent()
        default:return nil
        }
    }
}

class FilmModel : EVObject
{
    var film:String!
}

class FilmContent: UIShareContentDelegate
{
    func refresh(sender: UIShareContent, share: ShareThing?)
    {
        let mediaPlayer = sender.contentView as! ShareLinkFilmView
        if let json = share?.shareContent
        {
            if let film  = FilmModel(json: json).film
            {
                mediaPlayer.filePath = film
            }
        }else
        {
            mediaPlayer.filePath = nil
        }
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?)-> UIView
    {
        let player = ShareLinkFilmView(frame: sender.bounds)
        player.autoLoad = false
        player.fileFetcher = ServiceContainer.getService(FileService).getFileFetcherOfFileId(FileType.Video)
        return player
    }
}

class UIShareContent: UIView
{
    var delegate:UIShareContentDelegate!{
        didSet{
            contentView = delegate.getContentView(self, share: shareThing)
            self.addSubview(contentView)
        }
    }
    
    var shareThing:ShareThing!{
        didSet{
            update()
        }
    }
    
    private func update()
    {
        if delegate != nil && contentView != nil
        {
            delegate.refresh(self, share: shareThing)
        }
    }
    
    deinit{
        if contentView != nil
        {
            contentView.removeFromSuperview()
            contentView = nil
        }
    }
    
    private(set) var contentView:UIView!
}
