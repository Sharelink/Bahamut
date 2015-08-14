//
//  UIRecordButton.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/14.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import PBJVision

class UIRecordButtonController: UIViewController {

    var progressValue:Float = 0{
        didSet{
            if recordProgress != nil
            {
                recordProgress.angle = Int(360 * progressValue)
            }
        }
    }
    
    private var parentController:UICameraViewController!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("URBControllerView:\(self.view)")
        print("URBControllerView.superView:\(self.view.superview)")
        buttonInteractionView.userInteractionEnabled = true
        
        let doubleTapRecorgnizer = UITapGestureRecognizer(target: self, action: "doubleTapRecordButton:")
        doubleTapRecorgnizer.numberOfTapsRequired = 2
        self.buttonInteractionView.addGestureRecognizer(doubleTapRecorgnizer)
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
            case .Began:break
            case .Cancelled:break
            case .Changed:break;
            case .Ended:break
            case .Failed:break
            case .Possible:break
        }
    }
    
    @IBOutlet weak var buttonInteractionView: UIView!
    @IBOutlet weak var recordProgress: KDCircularProgress!
    @IBOutlet weak var tipsLabel: UILabel!
}
