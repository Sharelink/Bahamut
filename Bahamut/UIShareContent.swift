//
//  UIShareContent.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import AVFoundation

class UIShareContent: UIView
{
    var model:String!{
        didSet{
            update()
        }
    }
    
    func update()
    {
        if let moviePath = model
        {
            mediaPlayer.filePath = moviePath
        }else{
            mediaPlayer.filePath = nil
        }
    }
    
    deinit{
        mediaPlayer.filePath = nil
        mediaPlayer = nil
    }
    
    private(set) lazy var mediaPlayer:ShareLinkFilmView! = {
        let player = ShareLinkFilmView(frame: self.bounds)
        player.fileFetcher = ServiceContainer.getService(FileService).getFileFetcher(FileType.Video)
        self.addSubview(player)
        return player
    }()
}
