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
            case .Cancelled:fallthrough
            case .Ended:fallthrough
            case .Failed:parentController.pauseRecord()
        default:break
        }
    }
    
    @IBOutlet weak var buttonInteractionView: UIView!
    @IBOutlet weak var recordProgress: KDCircularProgress!
    @IBOutlet weak var tipsLabel: UILabel!
}
