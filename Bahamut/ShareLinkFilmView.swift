//
//  ShareLinkFilmView.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/11.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation

public class ShareLinkFilmView: UIView ,PlayerDelegate
{
    private var timer:NSTimer!{
        didSet{
            
        }
    }
    
    private var timeLine: UIProgressView!{
        didSet{
            timeLine.frame = CGRectMake(0, self.frame.height - 2, self.frame.width, 2)
            self.addSubview(timeLine)
        }
    }
    
    private var progress: KDCircularProgress!{
        didSet{
            
            progress.startAngle = -90
            progress.progressThickness = 0.2
            progress.trackThickness = 0.7
            progress.clockwise = true
            progress.gradientRotateSpeed = 2
            progress.roundedCorners = true
            progress.glowMode = .Forward
            progress.setColors(UIColor.cyanColor() ,UIColor.whiteColor(), UIColor.magentaColor())
            progress.frame = CGRectMake(self.frame.width / 2.0 - 16, self.frame.height / 2.0 - 16, 32, 32)
            self.addSubview(progress)
            setProgressValue(0)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var playerController:Player!{
        didSet{
            self.addSubview(playerController.view)
            playerController.view.frame = self.bounds
            playerController.delegate = self
            playerController.muted = true
            playerController.playbackLoops = true
            
        }
    }
    
    private func initGestures()
    {
        let clickVideoGesture = UITapGestureRecognizer(target: self, action: "playOrPausePlayer:")
        let doubleClickVideoGesture = UITapGestureRecognizer(target: self, action: "switchFullScreenOnOff:")
        doubleClickVideoGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(clickVideoGesture)
        self.addGestureRecognizer(doubleClickVideoGesture)
    }
    
    func playOrPausePlayer(_:UIGestureRecognizer! = nil)
    {
        if playerController.playbackState != PlaybackState.Playing
        {
            playerController.playFromCurrentTime()
        }else if playerController.playbackState == PlaybackState.Stopped
        {
            playerController.playFromBeginning()
        }else
        {
            playerController.pause()
        }
    }
    
    private var isVideoFullScreen:Bool = false
    func switchFullScreenOnOff(_:UIGestureRecognizer! = nil)
    {
        if isVideoFullScreen
        {
            scaleToMin()
        }else
        {
            scaleToMax()
        }
        print(progress.frame)
        isVideoFullScreen = !isVideoFullScreen
    }
    
    private func scaleToMax()
    {
        
        print("scale to full screen")
    }
    
    private func scaleToMin()
    {
        print("scale to min screen")
    }
    
    public override func didMoveToSuperview() {
        self.playerController = Player()
        progress = KDCircularProgress(frame: CGRectMake(0, 0, 32, 32))
        timeLine = UIProgressView()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "timerTime:", userInfo: nil, repeats: true)
    }
    
    func timerTime(_:NSTimer)
    {
        if self.playerController.playbackState != .Playing
        {
            return
        }
        if let currentFilm = self.playerController.player.currentItem
        {
            let a = CMTimeGetSeconds(currentFilm.currentTime())
            let b = CMTimeGetSeconds(currentFilm.duration)
            let c = a / b
            timeLine.progress = Float(c)
            setProgressValue(timeLine.progress)
        }
        
    }
    
    public func setProgressValue(value:Float)
    {
        progress.angle = Int(360 * value)
        if progress.angle > 0 && progress.angle <= 356
        {
            progress.hidden = false
        }else{
            progress.hidden = true
        }
    }
    
    public override func didMoveToWindow() {
        
        initGestures()
        
    }
    
    public var filePath:String!
    {
        didSet{
            if filePath == nil
            {
                playerController.reset()
            }else
            {
                playerController.path = filePath
            }
        }
    }
    
    deinit{
        playerController.reset()
    }
    
    public func playerReady(playerController: Player)
    {
        print("playerReady")
    }
    public func playerPlaybackStateDidChange(playerController: Player)
    {
        print("playerPlaybackStateDidChange")
        
    }
    public func playerBufferingStateDidChange(playerController: Player)
    {
        print("playerBufferingStateDidChange")
    }
    
    public func playerPlaybackWillStartFromBeginning(playerController: Player)
    {
        print("playerPlaybackWillStartFromBeginning")
    }
    public func playerPlaybackDidEnd(playerController: Player)
    {
    }

}