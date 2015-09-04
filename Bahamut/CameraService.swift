//
//  CameraService.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/16.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit


class CameraService: ServiceProtocol
{
    @objc static var ServiceName:String {return "camera service"}
    @objc func initService() {
        
    }
    
    func showCamera(currentNavigationController:UINavigationController, delegate:UICameraViewControllerDelegate!, videoFileSaveTo:(destination:String) -> Void)
    {
        let cameraController = UICameraViewController.instanceFromStoryBoard()
        cameraController.videoFileSaveTo = videoFileSaveTo
        currentNavigationController.pushViewController(cameraController, animated: true)
    }
}