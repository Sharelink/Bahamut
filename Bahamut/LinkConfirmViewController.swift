//
//  LinkConfirmViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/9/10.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

extension UserService
{
    func showLinkConfirmViewController(currentNavicationController:UINavigationController,linkMessage:LinkMessage)
    {
        let controller = LinkConfirmViewController.instanceFromStoryBoard()
        controller.linkMessage = linkMessage
        currentNavicationController.pushViewController(controller, animated: true)
    }
}

class LinkConfirmViewController: UIViewController
{
    var linkMessage:LinkMessage!
    @IBOutlet weak var noteNameField: UITextField!
    @IBOutlet weak var userNickLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    private func update()
    {
        userNickLabel.text = linkMessage.sharelinkerNick
        noteNameField.text = linkMessage.sharelinkerNick
    }
    
    @IBAction func ignore(sender: AnyObject)
    {
        dismissViewControllerAnimated(true){
            
        }
    }
    
    @IBAction func ok(sender: AnyObject)
    {
        let newNote = noteNameField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        dismissViewControllerAnimated(true){
            if newNote != nil && newNote!.isEmpty == false
            {
                ServiceContainer.getService(UserService).acceptUserLink(self.linkMessage.sharelinkerId,noteName: newNote!){ isSuc in
                    
                }
            }
        }
    }
    
    static func instanceFromStoryBoard() -> LinkConfirmViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "linkConfirmViewController") as! LinkConfirmViewController
    }
}