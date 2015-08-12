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
    var model:ShareContent!{
        didSet{
            var moviePath = NSBundle.mainBundle().pathForResource("02", ofType: "mov")
            var url = NSURL(fileURLWithPath: moviePath!)
            mediaPlayer.filePath = url?.path
        }
    }
    
    deinit{
        println("UIShareContent deinit")
        mediaPlayer.filePath = nil
        mediaPlayer = nil
    }
    
    private(set) lazy var mediaPlayer:ShareLinkFilmView! = {
        let player = ShareLinkFilmView(frame: self.bounds)
        self.addSubview(player)
        return player
    }()
}
