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

public class ShareLinkFilmView: UIView,ProgressTaskDelegate
{
    private var timer:NSTimer!{
        didSet{
            
        }
    }
    
    var fileFetcher:FileFetcher!{
        didSet{
            
        }
    }
    
    public var showTimeLine:Bool = true{
        didSet{
            if timeLine != nil
            {
                timeLine.hidden = !showTimeLine
            }
        }
    }
    private var timeLine: UIProgressView!{
        didSet{
            self.addSubview(timeLine)
            timeLine.hidden = !showTimeLine
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
    
    public var autoPlay:Bool = false
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
    var loading:Bool = false
    
    func startLoadVideo()
    {
        if filePath == nil || loading
        {
            return
        }
        loaded = false
        loading = true
        refreshButton.hidden = true
        setProgressValue(0)
        fileFetcher.startFetch(filePath,delegate: self)
    }
    
    func taskCompleted(fileIdentifier: String, result: AnyObject!)
    {
        self.loading = false
        self.setProgressValue(0)
        if let video = result as? String
        {
            self.playerController.path = video
            self.loaded = true
            self.refreshUI()
        }else
        {
            taskFailed(fileIdentifier, result: result)
        }
        
    }
    
    func taskProgress(fileIdentifier: String, persent: Float) {
        self.setProgressValue(persent / 100)
    }
    
    func taskFailed(fileIdentifier: String, result: AnyObject!)
    {
        self.loading = false
        self.setProgressValue(0)
        self.refreshButton.hidden = false
        self.playerController.reset()
    }
    
    convenience init()
    {
        self.init(frame: CGRectZero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initControls()
        initGestures()
        setNoVideo()
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("can't init from xib,please use addSubview() to load this view")
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
    
    private var playerController:Player!{
        didSet{
            self.addSubview(playerController.view)
            playerController.muted = isMute
            playerController.playbackLoops = isPlaybackLoops
            
        }
    }

    func playOrPausePlayer(_:UIGestureRecognizer! = nil)
    {
        if loaded
        {
            if playerController.playbackState == PlaybackState.Stopped
            {
                playerController.playFromBeginning()
            }else if playerController.playbackState != PlaybackState.Playing
            {
                playerController.playFromCurrentTime()
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
            self.frame = wFrame
            UIApplication.sharedApplication().keyWindow?.addSubview(self)
            isMute = true
            refreshUI()
        }
        
    }
    
    var isMute:Bool = true{
        didSet{
            if playerController != nil
            {
                playerController.muted = isMute
            }
        }
    }
    
    var isPlaybackLoops:Bool = true{
        didSet{
            if playerController != nil
            {
                playerController.playbackLoops = isPlaybackLoops
            }
        }
    }
    
    private func scaleToMin()
    {
        if originContainer == nil {return}
        self.removeFromSuperview()
        self.frame = minScreenFrame
        originContainer.addSubview(self)
        refreshUI()
    }

    public override func layoutSubviews()
    {
        self.frame = (superview?.bounds)!
        refreshUI()
        if minScreenFrame == nil
        {
            self.minScreenFrame = self.frame
        }
        if originContainer == nil
        {
            self.originContainer = self.superview
        }
        super.layoutSubviews()
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
        //progress.angle = Int(360 * value)
        print(Int(360 * value))
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
    
    class SharelinkFilmPlayerLayer : UIView
    {
        override init(frame: CGRect)
        {
            super.init(frame: frame)
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "closeView:"))
            self.backgroundColor = UIColor.blackColor()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func closeView(_:UIGestureRecognizer)
        {
            self.removeFromSuperview()
        }
    }
    
    static func showPlayer(currentController:UIViewController,uri:String,fileFetcer:FileFetcher)
    {
        
        let view = currentController.view.window!
        let width = min(view.bounds.width, view.bounds.height)
        let frame = CGRectMake(0, 0, width, width)
        let container = UIView(frame: frame)
        container.center = view.center
        let playerView = ShareLinkFilmView(frame: frame)
        playerView.autoLoad = true
        playerView.playerController.playbackLoops = false
        playerView.fileFetcher = fileFetcer
        let layer = SharelinkFilmPlayerLayer(frame: view.bounds)
        view.addSubview(layer)
        layer.addSubview(container)
        container.addSubview(playerView)
        playerView.filePath = uri
    }

}
