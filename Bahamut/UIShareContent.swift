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

protocol UIShareContentViewSetupDelegate
{
    func setupContentView(contentView:UIView, share:ShareThing)
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
    }
    
    func getContentView(sender: UIShareContent, share: ShareThing?)-> UIView
    {
        let player = ShareLinkFilmView(frame: sender.bounds)
        return player
    }
}

class UIShareContent: UIView
{
    var delegate:UIShareContentDelegate!
    var setupContentViewDelegate:UIShareContentViewSetupDelegate!
    
    var share:ShareThing!{
        didSet{
            if contentView != nil
            {
                contentView.removeFromSuperview()
            }
            contentView = delegate.getContentView(self, share: share)
            if setupContentViewDelegate != nil
            {
                setupContentViewDelegate.setupContentView(contentView, share: share)
            }
            self.addSubview(contentView)
        }
    }
    
    func update()
    {
        if delegate != nil && contentView != nil
        {
            self.delegate.refresh(self, share: self.share)
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
