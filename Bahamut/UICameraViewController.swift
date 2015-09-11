//
//  UICameraViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/13.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit
import PBJVision
import AssetsLibrary

@objc
protocol UICameraViewControllerDelegate
{
    optional func cameraCancelRecord(sender:UICameraViewController!)
    optional func cameraSaveRecordVideo(sender:UICameraViewController!, destination:String!)
}

class UICameraViewController: UIViewController , PBJVisionDelegate{
    var previewLayer:AVCaptureVideoPreviewLayer = PBJVision.sharedInstance().previewLayer
    var useFrontCamera:Bool{
        get{
            return NSUserDefaults.standardUserDefaults().boolForKey("useFrontCamera")
        }
        set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "useFrontCamera")
            if newValue && PBJVision.sharedInstance().isCameraDeviceAvailable(PBJCameraDevice.Front)
            {
                PBJVision.sharedInstance().cameraDevice = PBJCameraDevice.Front
            }else
            {
                PBJVision.sharedInstance().cameraDevice = PBJCameraDevice.Back
            }
        }
        
    }
    var currentVideo:NSDictionary?
    var assetLibrary:ALAssetsLibrary = ALAssetsLibrary()
    var recording:Bool = false
    var recordTimer:NSTimer!
    var delegate:UICameraViewControllerDelegate!
    private var videoSavedPath:String!
    @IBOutlet weak var recordButton: UIView!
    private var recordButtonController:UIRecordButtonController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initPreview()
        setup()
        initRecordButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        recordButton.hidden = true
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        recordButton.hidden = false
    }
    
    @IBOutlet weak var useVideoButton: UIBarButtonItem!{
        didSet{
            useVideoButton.enabled = false
        }
    }
    
    var cameraPreviewContainer: UIView! = UIView()
    
    func initRecordButton()
    {
        recordButtonController = self.childViewControllers.filter { $0 is UIRecordButtonController}.first as! UIRecordButtonController
        recordButtonController.didMoveToParentViewController(self)
        let moveRecorgnizer = UIPanGestureRecognizer(target: self, action: "moveRecordButton:")
        recordButton.addGestureRecognizer(moveRecorgnizer)
        self.view.bringSubviewToFront(recordButton)
        recordButtonController.progressValue = 0
    }
    
    func startTimer()
    {
        recordTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "recordTimer:", userInfo: nil, repeats: true)
    }
    
    func recordTimer(_:NSTimer)
    {
        let vision:PBJVision = PBJVision.sharedInstance()
        recordButtonController.progressValue = Float(vision.capturedVideoSeconds / 60)
    }
    
    @IBAction func cancelRecord(sender: AnyObject)
    {
        if let videoCancelRecord = delegate?.cameraCancelRecord
        {
            videoCancelRecord(self)
        }
    }
    
    @IBAction func useVideoBack(sender: AnyObject)
    {
        PBJVision.sharedInstance().endVideoCapture()
    }
    
    func moveRecordButton(recognizer:UIPanGestureRecognizer)
    {
        let point = recognizer.translationInView(self.view)
        recordButton.center = CGPointMake((recognizer.view?.center.x)! + point.x, (recognizer.view?.center.y)! + point.y)
        recognizer.setTranslation(CGPointMake(0, 0), inView: self.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initPreview()
    {
        cameraPreviewContainer.backgroundColor = UIColor.blackColor()
        cameraPreviewContainer.frame = self.view.bounds
        self.view.addSubview(cameraPreviewContainer)
        previewLayer.frame = cameraPreviewContainer.frame
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewContainer.layer.addSublayer(previewLayer)
        self.view.sendSubviewToBack(cameraPreviewContainer)
        initGesture()
    }
    
    func initGesture()
    {
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: "changeCamera:")
        rightSwipe.direction = .Right
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: "changeCamera:")
        leftSwipe.direction = .Left
        self.view.addGestureRecognizer(rightSwipe)
        self.view.addGestureRecognizer(leftSwipe)
    }
    
    func changeCamera(_:UISwipeGestureRecognizer)
    {
        useFrontCamera = !useFrontCamera
    }
    
    func setup()
    {
        let vision:PBJVision = PBJVision.sharedInstance()
        vision.delegate = self
        vision.cameraMode = PBJCameraMode.Video
        vision.cameraOrientation = PBJCameraOrientation.Portrait
        vision.focusMode = PBJFocusMode.ContinuousAutoFocus
        vision.outputFormat = PBJOutputFormat.Standard
        let useFrontCam = useFrontCamera
        useFrontCamera = useFrontCam
        vision.audioCaptureEnabled = true
        vision.maximumCaptureDuration = CMTimeMakeWithSeconds(60, 24)
        vision.startPreview()
    }
    
    func startOrResumeRecord()
    {
        if !recording {
            startTimer()
            useVideoButton.enabled = true
            PBJVision.sharedInstance().startVideoCapture()
            recording = true
        }
        else {
            PBJVision.sharedInstance().resumeVideoCapture()
        }
    }
    
    func pauseRecord()
    {
        PBJVision.sharedInstance().pauseVideoCapture()
    }
    
    func vision(vision: PBJVision, capturedVideo videoDict: [NSObject : AnyObject]?, error: NSError?) {
        currentVideo = videoDict
        recordTimer.invalidate()
        if error == nil
        {
            videoSavedPath = currentVideo?.objectForKey(PBJVisionVideoPathKey) as! String
            if videoSavedPath != nil
            {
                if let videoFileSaveTo = delegate.cameraSaveRecordVideo
                {
                    videoFileSaveTo(self,destination: videoSavedPath)
                }
                self.navigationController?.popViewControllerAnimated(true)
            }else
            {
                view.makeToast(message: "No Video Saved")
            }
        }else
        {
            useVideoButton.enabled = false
            recordButton.hidden = true
            view.makeToast(message: "Record Video Error")
            print(error?.description)
        }
    }
    
    func visionDidEndVideoCapture(vision: PBJVision)
    {
        self.navigationController?.navigationBarHidden = false
    }
    
    func visionDidPauseVideoCapture(vision: PBJVision)
    {
        self.navigationController?.navigationBarHidden = false
    }
    
    func visionDidResumeVideoCapture(vision: PBJVision)
    {
        self.navigationController?.navigationBarHidden = true
    }
    
    func visionDidStartVideoCapture(vision: PBJVision)
    {
        self.navigationController?.navigationBarHidden = true
    }
    
    deinit{
        if recordTimer != nil
        {
            recordTimer.invalidate()
            recordTimer = nil
        }
        PBJVision.sharedInstance().cancelVideoCapture()
    }
    
    static func instanceFromStoryBoard() -> UICameraViewController
    {
        return instanceFromStoryBoard("Component", identifier: "cameraViewController") as! UICameraViewController
    }
    
    static func showCamera(currentNavigationController:UINavigationController, delegate:UICameraViewControllerDelegate!) -> UICameraViewController
    {
        let cameraController = UICameraViewController.instanceFromStoryBoard()
        currentNavigationController.pushViewController(cameraController, animated: true)
        return cameraController
    }

}

class UIRecordButtonController: UIViewController {
    
    var progressValue:Float = 0{
        didSet{
            if recordProgress != nil
            {
                recordProgress.angle = Int(360 * progressValue)
            }
        }
    }
    
    @IBOutlet weak var tipsLabelTextField: UILabel!
    private var parentController:UICameraViewController!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        buttonInteractionView.userInteractionEnabled = true
        let longPressTapRecorgnizer = UILongPressGestureRecognizer(target: self, action: "longPressRecordButton:")
        self.buttonInteractionView.addGestureRecognizer(longPressTapRecorgnizer)
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        parentController = parent as? UICameraViewController
    }
    
    func doubleTapRecordButton(recognizer:UITapGestureRecognizer)
    {
        parentController.startOrResumeRecord()
    }
    
    func longPressRecordButton(recognizer:UILongPressGestureRecognizer)
    {
        switch recognizer.state
        {
        case .Began:parentController.startOrResumeRecord()
        tipsLabel.hidden = true
        case .Cancelled:fallthrough
        case .Ended:fallthrough
        case .Failed:parentController.pauseRecord()
        tipsLabel.hidden = false
        default:break
        }
    }
    
    @IBOutlet weak var buttonInteractionView: UIView!
    @IBOutlet weak var recordProgress: KDCircularProgress!
    @IBOutlet weak var tipsLabel: UILabel!
}
