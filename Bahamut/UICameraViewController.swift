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
    optional func videoCancelRecord(sender:UICameraViewController!)
}

class UICameraViewController: UIViewController , PBJVisionDelegate{
    var previewLayer:AVCaptureVideoPreviewLayer = PBJVision.sharedInstance().previewLayer
    
    var currentVideo:NSDictionary?
    var assetLibrary:ALAssetsLibrary = ALAssetsLibrary()
    var recording:Bool = false
    var recordTimer:NSTimer!
    var delegate:UICameraViewControllerDelegate!
    var videoFileSaveTo:((destination:String) -> Void)!
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
        if let videoCancelRecord = delegate?.videoCancelRecord
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
    }
    
    func setup()
    {
        let vision:PBJVision = PBJVision.sharedInstance()
        vision.delegate = self
        vision.cameraMode = PBJCameraMode.Video
        vision.cameraOrientation = PBJCameraOrientation.Portrait
        vision.focusMode = PBJFocusMode.AutoFocus
        vision.outputFormat = PBJOutputFormat.Standard
        vision.cameraDevice = PBJCameraDevice.Back
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
                if videoFileSaveTo != nil
                {
                    videoFileSaveTo(destination: videoSavedPath)
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
    
    deinit{
        if recordTimer != nil
        {
            recordTimer.invalidate()
            recordTimer = nil
        }
        PBJVision.sharedInstance().cancelVideoCapture()
    }

}
