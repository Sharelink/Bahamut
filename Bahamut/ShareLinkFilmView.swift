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
    
    var fileFetcher:FileFetcher!
    
    private var timeLine: UIProgressView!{
        didSet{
            self.addSubview(timeLine)
        }
    }
    
    var refreshButton:UIButton!{
        didSet{
            refreshButton.titleLabel?.text = "Load Video Error"
            refreshButton.hidden = true
            refreshButton.addTarget(self, action: "refreshButtonClick:", forControlEvents: UIControlEvents.TouchUpInside)
            self.addSubview(refreshButton)
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
            
            self.addSubview(progress)
            setProgressValue(0)
        }
    }
    
    public var autoLoad:Bool = false
    public var canSwitchToFullScreen = true
    
    public var filePath:String!
        {
        didSet{
            if filePath == nil
            {
                setNoVideo()
            }else if autoLoad
            {
                startLoadVideo()
            }
        }
    }
    
    func setNoVideo()
    {
        if playerController != nil
        {
            playerController.reset()
        }
        self.backgroundColor = UIColor.blackColor()
    }
    
    var loaded:Bool = false
    
    private func startLoadVideo()
    {
        if filePath == nil
        {
            return
        }
        loaded = false
        refreshButton.hidden = true
        setProgressValue(0)
        fileFetcher.startFetch(filePath, progress: { (persent) -> Void in
            self.setProgressValue(persent)
            }) { (error,video) -> Void in
                self.setProgressValue(0)
                if error
                {
                    self.playerController.path = NSBundle.mainBundle().pathForResource("02", ofType: ".mov")
                    //self.refreshButton.hidden = false
                    //self.playerController.reset()
                    self.loaded = true
                }else
                {
                    self.playerController.path = video
                    self.loaded = true
                }
                self.refreshUI()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initControls()
        initGestures()
        setNoVideo()
    }
    
    func initControls()
    {
        self.playerController = Player()
        progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        timeLine = UIProgressView()
        refreshButton = UIButton(type: UIButtonType.InfoDark)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "timerTime:", userInfo: nil, repeats: true)
        initObserver()
    }
    
    private func initGestures()
    {
        let clickVideoGesture = UITapGestureRecognizer(target: self, action: "playOrPausePlayer:")
        let doubleClickVideoGesture = UITapGestureRecognizer(target: self, action: "switchFullScreenOnOff:")
        doubleClickVideoGesture.numberOfTapsRequired = 2
        clickVideoGesture.requireGestureRecognizerToFail(doubleClickVideoGesture)
        self.addGestureRecognizer(clickVideoGesture)
        self.addGestureRecognizer(doubleClickVideoGesture)
    }
    
    func refreshButtonClick(_:UIButton)
    {
        startLoadVideo()
    }
    
    private func initObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeStatusBarOrientation:", name: UIApplicationDidChangeStatusBarOrientationNotification, object: UIApplication.sharedApplication())
    }
    
    func didChangeStatusBarOrientation(_: NSNotification)
    {
        if isVideoFullScreen
        {
            if let wFrame = UIApplication.sharedApplication().keyWindow?.bounds
            {
                UIApplication.sharedApplication().keyWindow?.addSubview(self)
                self.frame = wFrame
                refreshUI()
            }
        }
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var playerController:Player!{
        didSet{
            self.addSubview(playerController.view)
            playerController.delegate = self
            playerController.muted = true
            playerController.playbackLoops = true
            
        }
    }

    func playOrPausePlayer(_:UIGestureRecognizer! = nil)
    {
        if loaded
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
        }else
        {
            startLoadVideo()
        }
        
    }
    
    private var isVideoFullScreen:Bool = false{
        didSet{
            if canSwitchToFullScreen
            {
                isVideoFullScreen ? scaleToMax() : scaleToMin()
            }
        }
    }
    
    func switchFullScreenOnOff(_:UIGestureRecognizer! = nil)
    {
        isVideoFullScreen = !isVideoFullScreen
    }
    
    private var minScreenFrame:CGRect!
    private var originContainer:UIView!
    private func scaleToMax()
    {
        if let wFrame = UIApplication.sharedApplication().keyWindow?.bounds
        {
            self.removeFromSuperview()
            UIApplication.sharedApplication().keyWindow?.addSubview(self)
            self.frame = wFrame
            playerController.muted = false
            refreshUI()
        }
        
    }
    
    private func scaleToMin()
    {
        if originContainer == nil {return}
        self.removeFromSuperview()
        originContainer.addSubview(self)
        self.frame = minScreenFrame
        playerController.muted = true
        refreshUI()
    }
    
    public override func didMoveToSuperview()
    {
        if minScreenFrame == nil
        {
            self.minScreenFrame = self.frame
        }
        if originContainer == nil
        {
            self.originContainer = self.superview
        }
    }
    
    func refreshUI()
    {
        self.superview?.bringSubviewToFront(self)
        progress.center = self.center
        timeLine.frame = CGRectMake(0, self.frame.height - 2, self.frame.width, 2)
        playerController.view.frame = self.bounds
        refreshButton.center = self.center
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
        }
        
    }
    
    func setProgressValue(value:Float)
    {
        progress.angle = Int(360 * value)
        if progress.angle > 0 && progress.angle <= 356
        {
            progress.hidden = false
        }else{
            progress.hidden = true
        }
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
        playerController.reset()
    }
    
    public func playerReady(playerController: Player)
    {
    }
    public func playerPlaybackStateDidChange(playerController: Player)
    {
    }
    public func playerBufferingStateDidChange(playerController: Player)
    {
    }
    
    public func playerPlaybackWillStartFromBeginning(playerController: Player)
    {
    }
    public func playerPlaybackDidEnd(playerController: Player)
    {
    }

}