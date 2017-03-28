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
import KDCircularProgress

public protocol BahamutFilmViewDelegate{
    func bahamutFilmViewOnDraw(_ sender:BahamutFilmView,rect:CGRect)
}

//MARK: BahamutFilmView
open class BahamutFilmView: UIView,ProgressTaskDelegate,PlayerDelegate
{
    
    //MARK: Inits
    convenience init()
    {
        self.init(frame: CGRect.zero)
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
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(BahamutFilmView.timerTime(_:)), userInfo: nil, repeats: true)
        initObserver()
    }
    
    fileprivate func initGestures()
    {
        let clickVideoGesture = UITapGestureRecognizer(target: self, action: #selector(BahamutFilmView.playOrPausePlayer(_:)))
        let doubleClickVideoGesture = UITapGestureRecognizer(target: self, action: #selector(BahamutFilmView.switchFullScreenOnOff(_:)))
        doubleClickVideoGesture.numberOfTapsRequired = 2
        clickVideoGesture.require(toFail: doubleClickVideoGesture)
        self.addGestureRecognizer(clickVideoGesture)
        self.addGestureRecognizer(doubleClickVideoGesture)
    }
    
    
    fileprivate func initObserver()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(BahamutFilmView.didChangeStatusBarOrientation(_:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: UIApplication.shared)
    }
    
    func releasePlayer() {
        NotificationCenter.default.removeObserver(self)
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
    var viewDelegate:BahamutFilmViewDelegate?
    
    
    fileprivate var timer:Timer!
    
    var fileFetcher:FileFetcher!
    
    fileprivate(set) var playerController:Player!{
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
    
    fileprivate var thumbImageView:UIImageView!{
        didSet{
            thumbImageView.isHidden = true
            self.addSubview(thumbImageView)
        }
    }

    fileprivate var timeLine: UIProgressView!{
        didSet{
            self.addSubview(timeLine)
            timeLine.isHidden = true
            timeLine.backgroundColor = UIColor.clear
        }
    }
    
    var refreshButton:UIImageView!{
        didSet{
            refreshButton.isUserInteractionEnabled = true
            refreshButton.image = UIImage(named:"refresh")
            refreshButton.isHidden = true
            refreshButton.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(BahamutFilmView.refreshButtonClick(_:))))
            self.addSubview(refreshButton)
        }
    }
    
    var playButton:UIImageView!{
        didSet{
            playButton.image = UIImage(named: "playGray")
            playButton.isHidden = false
            
            self.addSubview(playButton)
        }
    }
    
    var noFileImage:UIImageView!{
        didSet{
            noFileImage.image = UIImage(named:"delete")
            noFileImage.isHidden = true
            self.addSubview(noFileImage)
        }
    }
    
    fileprivate var fileProgress: KDCircularProgress!{
        didSet{
            fileProgress.startAngle = -90
            fileProgress.progressThickness = 0.2
            fileProgress.trackThickness = 0.7
            fileProgress.clockwise = true
            fileProgress.gradientRotateSpeed = 2
            fileProgress.roundedCorners = true
            fileProgress.glowMode = .forward
            fileProgress.set(colors: UIColor.cyan ,UIColor.white, UIColor.magenta)
            fileProgress.center = self.center
            self.addSubview(fileProgress)
            fileProgress.angle = 0
        }
    }
    //MARK: thumb
    open func setThumb(_ img:UIImage)
    {
        self.thumbImageView.image = img
        self.thumbImageView.isHidden = false
        self.refreshUI()
    }
    
    open func clearThumb()
    {
        self.thumbImageView.image = nil
        self.thumbImageView.isHidden = true
        self.refreshUI()
    }
    
    //MARK: film file
    open var filePath:String!
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
                noFileImage.isHidden = true
                playButton.isHidden = false
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
        noFileImage.isHidden = false
        playButton.isHidden = true
        refreshButton.isHidden = true
        self.backgroundColor = UIColor.black
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
        refreshButton.isHidden = true
        playButton.isHidden = true
        fileProgress.angle = 0
        fileProgress.isHidden = false
        fileFetcher.startFetch(filePath,delegate: self)
    }
    
    open func taskCompleted(_ fileIdentifier: String, result: Any!)
    {
        self.fileProgress.angle = 0
        DispatchQueue.main.async { () -> Void in
            self.loading = false
            self.playButton.isHidden = false
            self.refreshButton.isHidden = true
            self.fileProgress.isHidden = true
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
    
    open func taskProgress(_ fileIdentifier: String, persent: Float) {
        self.fileProgress.angle = Double(360 * persent / 100)
        self.progressDelegate?.taskProgress?(fileIdentifier, persent: persent)
    }
    
    open func taskFailed(_ fileIdentifier: String, result: Any!)
    {
        fileProgress.angle = 0
        DispatchQueue.main.async { () -> Void in
            self.loading = false
            self.refreshButton.isHidden = false
            self.playButton.isHidden = true
            self.fileProgress.isHidden = true
            self.playerController.reset()
            self.progressDelegate?.taskFailed?(fileIdentifier, result: result)
        }
        
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        if minScreenFrame == nil
        {
            self.minScreenFrame = rect
        }
        if originContainer == nil
        {
            self.originContainer = self.superview
        }
        
        self.fileProgress.center = self.center
        self.timeLine.frame = CGRect(x: 0, y: self.frame.height - 2, width: self.frame.width, height: 2)
        self.playerController.view.frame = rect
        self.thumbImageView.frame = self.bounds
        noFileImage?.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        noFileImage?.center = self.center
        playButton?.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        playButton?.center = self.center
        refreshButton?.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        refreshButton?.center = self.center
        viewDelegate?.bahamutFilmViewOnDraw(self, rect: rect)
    }

    //MARK: actions
    func refreshButtonClick(_:UIButton)
    {
        startLoadVideo()
    }

    func didChangeStatusBarOrientation(_: Notification)
    {
        if isVideoFullScreen
        {
            if let wFrame = UIApplication.shared.keyWindow?.bounds
            {
                UIApplication.shared.keyWindow?.addSubview(self)
                self.frame = wFrame
                refreshUI()
            }
        }
        
    }

    
    fileprivate(set) var isVideoFullScreen:Bool = false{
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
    
    fileprivate var minScreenFrame:CGRect!
    fileprivate var originContainer:UIView!
    fileprivate func scaleToMax()
    {
        if let wFrame = UIApplication.shared.keyWindow?.bounds
        {
            self.removeFromSuperview()
            self.frame = wFrame
            UIApplication.shared.keyWindow?.addSubview(self)
            timeLine.isHidden = !showTimeLine
            refreshUI()
        }
        
    }

    
    fileprivate func scaleToMin()
    {
        if originContainer == nil {return}
        self.removeFromSuperview()
        self.frame = minScreenFrame
        self.timeLine.isHidden = true
        originContainer.addSubview(self)
        refreshUI()
    }
    
    fileprivate func refreshUI()
    {
        DispatchQueue.main.async { () -> Void in
            self.superview?.bringSubview(toFront: self)
            self.bringSubview(toFront: self.fileProgress)
            self.bringSubview(toFront: self.timeLine)
            self.bringSubview(toFront: self.refreshButton)
            self.bringSubview(toFront: self.playButton)
            self.bringSubview(toFront: self.noFileImage)
        }
        
    }
    
    func timerTime(_:Timer)
    {
        if self.playerController?.playbackState != .playing
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

    open var autoPlay:Bool = false
    open var autoLoad:Bool = false
    open var canSwitchToFullScreen = true
    
    open var showTimeLine:Bool = true{
        didSet{
            if timeLine != nil
            {
                timeLine.isHidden = !showTimeLine
            }
            if self.isVideoFullScreen == false
            {
                self.timeLine.isHidden = true
            }
        }
    }
    
    open var isMute:Bool = true{
        didSet{
            if playerController != nil
            {
                playerController.muted = isMute
            }
        }
    }
    
    open var isPlaybackLoops:Bool = true{
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
            if playerController.playbackState == PlaybackState.stopped
            {
                playerController.playFromBeginning()
            }else if playerController.playbackState != PlaybackState.playing
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
    open func playerBufferingStateDidChange(_ player: Player) {
        if player.playbackState! == .stopped && player.bufferingState == BufferingState.ready && autoPlay
        {
            autoPlay = isPlaybackLoops
            player.playFromBeginning()
        }
        if let handler = delegate?.playerBufferingStateDidChange{
            handler(player)
        }
    }
    
    open func playerPlaybackDidEnd(_ player: Player)
    {
        if let handler = delegate?.playerPlaybackDidEnd{
            handler(player)
        }
    }
    
    open func playerPlaybackStateDidChange(_ player: Player)
    {

        switch player.playbackState!
        {
        case PlaybackState.playing:
            playButton.isHidden = true
        case PlaybackState.stopped:fallthrough
        case PlaybackState.paused:
            playButton.isHidden = false
        case .failed:
            playButton.isHidden = true
            refreshButton.isHidden = false
        }
        
        if let handler = delegate?.playerPlaybackStateDidChange{
            handler(player)
        }
    }
    
    open func playerPlaybackWillStartFromBeginning(_ player: Player)
    {
        if let handler = delegate?.playerPlaybackWillStartFromBeginning{
            handler(player)
        }
    }
    
    open func playerReady(_ player: Player)
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
            self.backgroundColor = UIColor.black
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func closeView(_:UIGestureRecognizer)
        {
            self.removeFromSuperview()
        }
    }
    
    static func showPlayer(_ currentController:UIViewController,uri:String,fileFetcer:FileFetcher)
    {
        
        let view = currentController.view.window!
        let width = min(view.bounds.width, view.bounds.height)
        let frame = CGRect(x: 0, y: 0, width: width, height: width)
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
