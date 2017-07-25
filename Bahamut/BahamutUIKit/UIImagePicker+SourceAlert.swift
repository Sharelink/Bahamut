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
    static func showUIImagePickerAlert(_ viewController:UIViewController,title:String!,message:String!,allowsEditing:Bool = false,alertStyle:UIAlertControllerStyle = .actionSheet,extraAlertAction:[UIAlertAction]? = nil) -> UIImagePickerController{
        let imagePicker = UIImagePickerController()
        let style = UIDevice.current.userInterfaceIdiom == .phone ? alertStyle : .alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let camera = UIAlertAction(title: "TAKE_NEW_PHOTO".bahamutCommonLocalizedString, style: .default) { _ in
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = allowsEditing
            viewController.present(imagePicker, animated: true, completion: nil)
        }
        
        if let cameraIcon = UIImage(named: "avartar_camera")?.withRenderingMode(.alwaysOriginal) {
            camera.setValue(cameraIcon, forKey: "image")
        }
        
        if !UIDevice.isSimulator() {
            alert.addAction(camera)
        }
        
        let album = UIAlertAction(title:"SELECT_PHOTO".bahamutCommonLocalizedString, style: .default) { _ in
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = allowsEditing
            viewController.present(imagePicker, animated: true, completion: nil)
        }
        if let albumIcon = UIImage(named: "avartar_select")?.withRenderingMode(.alwaysOriginal){
            album.setValue(albumIcon, forKey: "image")
        }
        alert.addAction(album)
        
        if let exActs = extraAlertAction{
            for ac in exActs {
                alert.addAction(ac)
            }
        }
        
        alert.addAction(UIAlertAction(title: "CANCEL".bahamutCommonLocalizedString, style: .cancel){ _ in})
        viewController.present(alert, animated: true, completion: nil)
        return imagePicker
    }
}

