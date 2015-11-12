//
//  QuPaiRecordCameraViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class QuPaiRecordCamera
{
    func getQuPaiController(delegate:QupaiSDKDelegate,sec:Int = 30) -> UINavigationController?
    {
        let taeSdk = TaeSDK.sharedInstance()
        if let sdk = taeSdk.getQuPaiSDk()
        {
            sdk.delegte  = delegate
            let recordController = sdk.createRecordViewControllerWithMaxDuration(CGFloat(sec),
                bitRate: 800 * 1000,
                thumbnailCompressionQuality: 0.3,
                watermarkImage: nil,
                watermarkPosition: QupaiSDKWatermarkPosition.TopRight,
                tintColor: UIColor.themeColor,
                enableMoreMusic: false,
                enableImport: false,
                enableVideoEffect: true)
            
            let navigation = UINavigationController(rootViewController: recordController)
            navigation.navigationBarHidden = true
            return navigation
        }
        return nil
    }
}