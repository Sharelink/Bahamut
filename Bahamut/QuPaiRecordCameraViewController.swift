//
//  QuPaiRecordCameraViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/12.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

protocol QupaiSDKDelegate {
    
}

class QuPaiRecordCamera
{
    func getQuPaiController(delegate:QupaiSDKDelegate,sec:Int = 30) -> UINavigationController?
    {
        #if APP_VERSION
/*
        if let sdk = QupaiSDK.shared()
        {
            sdk.delegte  = delegate
            
            let recordController = sdk.createRecordViewControllerWithMinDuration(5,maxDuration:CGFloat(sec),bitRate: 800 * 1000)
            let navigation = UINavigationController(rootViewController: recordController)
            navigation.navigationBarHidden = true
            return navigation
        }
 */
        #endif
        return nil
    }
}