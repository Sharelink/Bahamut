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

//MARK: ShareLinkFilmView
public class ShareLinkFilmView: UIView,ProgressTaskDelegate,PlayerDelegate
{
    
    //MARK: Inits
    
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
    
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if playerController != nil
        {
            playerController.path = nil
            playerController.reset()
        }
    }
    
    func initControls()
    {
        self.playerController = Player()
        self.thumbImageView = UIImageView()
        fileProgress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        timeLine = UIProgressView()
        refreshButton = UIImageView()
        playButton = UIImageView()
        noFileImage = UIImageView()
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
    
    
    private func initObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeStatusBarOrientation:", name: UIApplicationDidChangeStatusBarOrientationNotification, object: UIApplication.sharedApplication())
    }
    
    //MARK: ui properties
    private var timer:NSTimer!{
        didSet{
            
        }
    }
    
    var fileFetcher:FileFetcher!{
        didSet{
            
        }
    }
    
    private(set) var playerController:Player!{
        didSet{
            playerController.reset()
            self.playerController.delegate = self
            self.addSubview(playerController.view)
            playerController.muted = isMute
            playerController.playbackLoops = isPlaybackLoops
            
        }
    }
    
    private var thumbImageView:UIImageView!{
        didSet{
            thumbImageView.hidden = true
            self.addSubview(thumbImageView)
        }
    }

    private var timeLine: UIProgressView!{
        didSet{
            self.addSubview(timeLine)
            timeLine.hidden = true
            timeLine.backgroundColor = UIColor.clearColor()
        }
    }
    
    var refreshButton:UIImageView!{
        didSet{
            refreshButton.userInteractionEnabled = true
            refreshButton.frame = CGRectMake(0, 0, 48, 48)
            refreshButton.image = UIImage(named: "refresh")
            refreshButton.hidden = true
            refreshButton.center = self.center
            refreshButton.addGestureRecognizer(UITapGestureRecognizer(target:self, action: "refreshButtonClick:"))
            self.addSubview(refreshButton)
        }
    }
    
    var playButton:UIImageView!{
        didSet{
            playButton.frame = CGRectMake(0, 0, 48, 48)
            playButton.image = UIImage(named: "playGray")
            playButton.hidden = false
            playButton.center = self.center
            self.addSubview(playButton)
        }
    }
    
    var noFileImage:UIImageView!{
        didSet{
            noFileImage.frame = CGRectMake(0, 0, 48, 48)
            noFileImage.image = UIImage(named: "delete")
            noFileImage.hidden = true
            noFileImage.center = self.center
            self.addSubview(noFileImage)
        }
    }
    
    private var fileProgress: KDCircularProgress!{
        didSet{
            
            fileProgress.startAngle = -90
            fileProgress.progressThickness = 0.2
            fileProgress.trackThickness = 0.7
            fileProgress.clockwise = true
            fileProgress.gradientRotateSpeed = 2
            fileProgress.roundedCorners = true
            fileProgress.glowMode = .Forward
            fileProgress.setColors(UIColor.cyanColor() ,UIColor.whiteColor(), UIColor.magentaColor())
            fileProgress.center = self.center
            self.addSubview(fileProgress)
            fileProgress.setProgressValue(0)
        }
    }
    //MARK: thumb
    public func setThumb(img:UIImage)
    {
        self.thumbImageView.image = img
        self.thumbImageView.hidden = false
        self.refreshUI()
    }
    
    public func clearThumb()
    {
        self.thumbImageView.image = nil
        self.thumbImageView.hidden = true
        self.refreshUI()
    }
    
    //MARK: film file
    public var filePath:String!
        {
        didSet{
            if filePath == nil
            {
                setNoVideo()
            }else
            {
                noFileImage.hidden = true
                playButton.hidden = false
                if autoLoad
                {
                    startLoadVideo()
                }
            }
        }
    }
    
    func setNoVideo()
    {
        if playerController != nil
        {
            playerController.reset()
        }
        noFileImage.hidden = false
        playButton.hidden = true
        refreshButton.hidden = true
        self.backgroundColor = UIColor.blackColor()
        self.refreshUI()
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
        playButton.hidden = true
        fileProgress.setProgressValue(0)
        fileFetcher.startFetch(filePath,delegate: self)
    }
    
    public func taskCompleted(fileIdentifier: String, result: AnyObject!)
    {
        self.fileProgress.setProgressValue(0)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.loading = false
            self.playButton.hidden = false
            self.refreshButton.hidden = true
            if let video = result as? String
            {
                self.playerController.path = video
                self.loaded = true
                self.clearThumb()
                self.refreshUI()
            }else
            {
                self.taskFailed(fileIdentifier, result: result)
                self.refreshUI()
            }
        }
        
        
    }
    
    public func taskProgress(fileIdentifier: String, persent: Float) {
        self.fileProgress.setProgressValue(persent / 100)
    }
    
    public func taskFailed(fileIdentifier: String, result: AnyObject!)
    {
        fileProgress.setProgressValue(0)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.loading = false
            self.refreshButton.hidden = false
            self.playButton.hidden = true
            self.playerController.reset()
        }
        
    }

    //MARK: actions
    func refreshButtonClick(_:UIButton)
    {
        startLoadVideo()
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
    
    //MARK: UI refresh
    
    private var minScreenFrame:CGRect!
    private var originContainer:UIView!
    private func scaleToMax()
    {
        if let wFrame = UIApplication.sharedApplication().keyWindow?.bounds
        {
            self.removeFromSuperview()
            self.frame = wFrame
            UIApplication.sharedApplication().keyWindow?.addSubview(self)
            timeLine.hidden = !showTimeLine
            refreshUI()
        }
        
    }

    
    private func scaleToMin()
    {
        if originContainer == nil {return}
        self.removeFromSuperview()
        self.frame = minScreenFrame
        self.timeLine.hidden = true
        originContainer.addSubview(self)
        refreshUI()
    }

    public override func layoutSubviews()
    {
        if let frame = superview?.bounds
        {
            self.frame = frame
        }else
        {
            return
        }
        
        if minScreenFrame == nil
        {
            self.minScreenFrame = self.frame
        }
        if originContainer == nil
        {
            self.originContainer = self.superview
        }
        
        self.fileProgress.center = self.center
        self.timeLine.frame = CGRectMake(0, self.frame.height - 2, self.frame.width, 2)
        self.playerController.view.frame = self.bounds
        self.thumbImageView.frame = self.bounds
        self.refreshButton.center = self.center
        self.playButton.center = self.center
        self.noFileImage.center = self.center
        
        super.layoutSubviews()
    }
    
    private func refreshUI()
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.superview?.bringSubviewToFront(self)
            
            self.bringSubviewToFront(self.fileProgress)
            self.bringSubviewToFront(self.timeLine)
            self.bringSubviewToFront(self.refreshButton)
            self.bringSubviewToFront(self.playButton)
            self.bringSubviewToFront(self.noFileImage)
        }
        
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

    //MARK: player control

    public var autoPlay:Bool = false
    public var autoLoad:Bool = false
    public var canSwitchToFullScreen = true
    
    public var showTimeLine:Bool = true{
        didSet{
            if timeLine != nil
            {
                timeLine.hidden = !showTimeLine
            }
            if self.isVideoFullScreen == false
            {
                self.timeLine.hidden = true
            }
        }
    }
    
    public var isMute:Bool = true{
        didSet{
            if playerController != nil
            {
                playerController.muted = isMute
            }
        }
    }
    
    public var isPlaybackLoops:Bool = true{
        didSet{
            if playerController != nil
            {
                playerController.playbackLoops = isPlaybackLoops
            }
        }
    }
    
    func playOrPausePlayer(_:UIGestureRecognizer! = nil)
    {
        autoPlay = true
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
    
    //MARK: playerDelegate
    public func playerBufferingStateDidChange(player: Player) {
        if player.playbackState! == .Stopped && player.bufferingState == BufferingState.Ready && autoPlay
        {
            player.playFromBeginning()
        }
    }
    
    public func playerPlaybackDidEnd(player: Player)
    {
        
    }
    
    public func playerPlaybackStateDidChange(player: Player)
    {

        switch player.playbackState!
        {
        case PlaybackState.Playing:
            playButton.hidden = true
        case PlaybackState.Stopped:fallthrough
        case PlaybackState.Paused:
            playButton.hidden = false
        case .Failed:
            playButton.hidden = true
            refreshButton.hidden = false
        }
    }
    
    public func playerPlaybackWillStartFromBeginning(player: Player)
    {
        
    }
    
    public func playerReady(player: Player)
    {
        
    }
    
    //MARK: show player
    
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
