//
//  UIImagePicker+SourceAlert.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

extension UIImagePickerController{
    static func showUIImagePickerAlert(viewController:UIViewController,title:String!,message:String!,allowsEditing:Bool = false,alertStyle:UIAlertControllerStyle = .ActionSheet) -> UIImagePickerController{
        let imagePicker = UIImagePickerController()
        let alert = UIAlertController(title: title, message: message, preferredStyle: alertStyle)
        let camera = UIAlertAction(title: "TAKE_NEW_PHOTO".bahamutCommonLocalizedString, style: .Default) { _ in
            imagePicker.sourceType = .Camera
            imagePicker.allowsEditing = allowsEditing
            viewController.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        if let cameraIcon = UIImage(named: "avartar_camera")?.imageWithRenderingMode(.AlwaysOriginal) {
            camera.setValue(cameraIcon, forKey: "image")
        }
        
        if !isInSimulator() {
            alert.addAction(camera)
        }
        
        let album = UIAlertAction(title:"SELECT_PHOTO".bahamutCommonLocalizedString, style: .Default) { _ in
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.allowsEditing = allowsEditing
            viewController.presentViewController(imagePicker, animated: true, completion: nil)
        }
        if let albumIcon = UIImage(named: "avartar_select")?.imageWithRenderingMode(.AlwaysOriginal){
            album.setValue(albumIcon, forKey: "image")
        }
        alert.addAction(album)
        alert.addAction(UIAlertAction(title: "CANCEL".bahamutCommonLocalizedString, style: .Cancel){ _ in})
        viewController.presentViewController(alert, animated: true, completion: nil)
        return imagePicker
    }
}

