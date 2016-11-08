//
//  BahamutFilmView.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/11.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation

//MARK: BahamutFilmView
public class BahamutFilmView: UIView,ProgressTaskDelegate,PlayerDelegate
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
        super.init(coder: aDecoder)
        initControls()
        initGestures()
        setNoVideo()
    }
    
    
    deinit{
        releasePlayer()
        #if DEBUG
            print("BahamutFilmView Deinited")
        #endif
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
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(BahamutFilmView.timerTime(_:)), userInfo: nil, repeats: true)
        initObserver()
    }
    
    private func initGestures()
    {
        let clickVideoGesture = UITapGestureRecognizer(target: self, action: #selector(BahamutFilmView.playOrPausePlayer(_:)))
        let doubleClickVideoGesture = UITapGestureRecognizer(target: self, action: #selector(BahamutFilmView.switchFullScreenOnOff(_:)))
        doubleClickVideoGesture.numberOfTapsRequired = 2
        clickVideoGesture.requireGestureRecognizerToFail(doubleClickVideoGesture)
        self.addGestureRecognizer(clickVideoGesture)
        self.addGestureRecognizer(doubleClickVideoGesture)
    }
    
    
    private func initObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BahamutFilmView.didChangeStatusBarOrientation(_:)), name: UIApplicationDidChangeStatusBarOrientationNotification, object: UIApplication.sharedApplication())
    }
    
    func releasePlayer() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer?.invalidate()
        timer = nil
        self.delegate = nil
        playerController?.path = nil
        playerController?.reset()
        playerController = nil
    }
    
    //MARK: properties
    var delegate:PlayerDelegate!
    weak var progressDelegate:ProgressTaskDelegate!
    
    private var timer:NSTimer!
    
    var fileFetcher:FileFetcher!
    
    private(set) var playerController:Player!{
        didSet{
            if playerController == nil {
                return
            }
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
            refreshButton.image = UIImage(named:"refresh")
            refreshButton.hidden = true
            refreshButton.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(BahamutFilmView.refreshButtonClick(_:))))
            self.addSubview(refreshButton)
        }
    }
    
    var playButton:UIImageView!{
        didSet{
            playButton.image = UIImage(named: "playGray")
            playButton.hidden = false
            
            self.addSubview(playButton)
        }
    }
    
    var noFileImage:UIImageView!{
        didSet{
            noFileImage.image = UIImage(named:"delete")
            noFileImage.hidden = true
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
            fileProgress.angle = 0
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
            if filePath != oldValue{
                playerController.stop()
                setNoVideo()
                loading = false
                loaded = false
            }
            if filePath != nil
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
        fileProgress.angle = 0
        fileProgress.hidden = false
        fileFetcher.startFetch(filePath,delegate: self)
    }
    
    public func taskCompleted(fileIdentifier: String, result: AnyObject!)
    {
        self.fileProgress.angle = 0
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.loading = false
            self.playButton.hidden = false
            self.refreshButton.hidden = true
            self.fileProgress.hidden = true
            if let video = result as? String
            {
                self.playerController.path = video
                self.loaded = true
                self.clearThumb()
                self.refreshUI()
                self.progressDelegate?.taskCompleted(fileIdentifier, result: result)
            }else
            {
                self.taskFailed(fileIdentifier, result: result)
                self.refreshUI()
            }
            
        }
        
        
    }
    
    public func taskProgress(fileIdentifier: String, persent: Float) {
        self.fileProgress.angle = Double(360 * persent / 100)
        self.progressDelegate?.taskProgress?(fileIdentifier, persent: persent)
    }
    
    public func taskFailed(fileIdentifier: String, result: AnyObject!)
    {
        fileProgress.angle = 0
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.loading = false
            self.refreshButton.hidden = false
            self.playButton.hidden = true
            self.fileProgress.hidden = true
            self.playerController.reset()
            self.progressDelegate?.taskFailed?(fileIdentifier, result: result)
        }
        
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if minScreenFrame == nil
        {
            self.minScreenFrame = rect
        }
        if originContainer == nil
        {
            self.originContainer = self.superview
        }
        
        self.fileProgress.center = self.center
        self.timeLine.frame = CGRectMake(0, self.frame.height - 2, self.frame.width, 2)
        self.playerController.view.frame = rect
        self.thumbImageView.frame = self.bounds
        noFileImage?.frame = CGRectMake(0, 0, 36, 36)
        noFileImage?.center = self.center
        playButton?.frame = CGRectMake(0, 0, 36, 36)
        playButton?.center = self.center
        refreshButton?.frame = CGRectMake(0, 0, 36, 36)
        refreshButton?.center = self.center
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

    
    private(set) var isVideoFullScreen:Bool = false{
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
        if self.playerController?.playbackState != .Playing
        {
            return
        }
        if let currentFilm = self.playerController?.player?.currentItem
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
            autoPlay = isPlaybackLoops
            player.playFromBeginning()
        }
        if let handler = delegate?.playerBufferingStateDidChange{
            handler(player)
        }
    }
    
    public func playerPlaybackDidEnd(player: Player)
    {
        if let handler = delegate?.playerPlaybackDidEnd{
            handler(player)
        }
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
        
        if let handler = delegate?.playerPlaybackStateDidChange{
            handler(player)
        }
    }
    
    public func playerPlaybackWillStartFromBeginning(player: Player)
    {
        if let handler = delegate?.playerPlaybackWillStartFromBeginning{
            handler(player)
        }
    }
    
    public func playerReady(player: Player)
    {
        if let handler = delegate?.playerReady{
            handler(player)
        }
    }
    
    //MARK: show player
    
    class BahamutFilmPlayerLayer : UIView
    {
        override init(frame: CGRect)
        {
            super.init(frame: frame)
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BahamutFilmPlayerLayer.closeView(_:))))
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
        let playerView = BahamutFilmView(frame: frame)
        playerView.autoLoad = true
        playerView.playerController.playbackLoops = false
        playerView.fileFetcher = fileFetcer
        let layer = BahamutFilmPlayerLayer(frame: view.bounds)
        view.addSubview(layer)
        layer.addSubview(container)
        container.addSubview(playerView)
        playerView.filePath = uri
    }

}
