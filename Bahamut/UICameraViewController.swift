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

class UICameraViewController: UIViewController , PBJVisionDelegate{
    var previewLayer:AVCaptureVideoPreviewLayer = PBJVision.sharedInstance().previewLayer
    
    var currentVideo:NSDictionary?
    var assetLibrary:ALAssetsLibrary = ALAssetsLibrary()
    var recording:Bool = false
    var recordTimer:NSTimer!
    var filePath:String!
    @IBOutlet weak var recordButton: UIView!
    private var recordButtonController:UIRecordButtonController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        initPreview()
        setup()
        initRecordButton()
    }
    
    var cameraPreviewContainer: UIView! = UIView()
    
    func initRecordButton()
    {
        recordButtonController = self.childViewControllers.filter { $0 is UIRecordButtonController}.first as! UIRecordButtonController
        recordButtonController.didMoveToParentViewController(self)
        let moveRecorgnizer = UIPanGestureRecognizer(target: self, action: "moveRecordButton:")
        recordButton.frame = CGRectMake(self.view.frame.width / 2, self.view.frame.height - 130, 128, 128)
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
        vision.maximumCaptureDuration = CMTimeMakeWithSeconds(60, 24)
        vision.startPreview()
    }
    
    func startOrResumeRecord()
    {
        if !recording {
            PBJVision.sharedInstance().startVideoCapture()
            recording = true
            startTimer()
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
        let videoPath:String = currentVideo?.objectForKey(PBJVisionVideoPathKey) as! String
        recordTimer.invalidate()
        do{
            try NSFileManager.defaultManager().moveItemAtPath(videoPath, toPath: filePath!)
        }catch let error as NSError
        {
            print(error.description)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
