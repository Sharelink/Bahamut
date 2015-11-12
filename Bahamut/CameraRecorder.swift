//
//  CameraRecorder.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

@objc
protocol UICameraViewControllerDelegate
{
    optional func cameraCancelRecord(sender:AnyObject!)
    optional func cameraSaveRecordVideo(sender:AnyObject!, destination:String!)
}
