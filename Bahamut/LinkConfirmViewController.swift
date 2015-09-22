//
//  LinkConfirmViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class LinkConfirmViewController: UIViewController
{
    var sharelinker:ShareLinkUser!
    @IBOutlet weak var noteNameField: UITextField!
    @IBOutlet weak var userNickLabel: UILabel!
    
    private func update()
    {
        userNickLabel.text = sharelinker.nickName
    }
    
    @IBAction func ignore(sender: AnyObject)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func ok(sender: AnyObject)
    {
        let newNote = noteNameField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        dismissViewControllerAnimated(true){
            if newNote != nil && newNote!.isEmpty == false
            {
                ServiceContainer.getService(UserService).acceptUserLink(self.sharelinker.userId,noteName: newNote!){ isSuc in
                    
                }
            }
        }
        
    }
}