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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    private func update()
    {
        noteNameField.text = linkMessage.message
        
        if linkMessage.message == "ASK_LINK_MSG" //old version before 1.2.1, if all user updated new than 1.2.1,remove this
        {
            noteNameField.text = linkMessage.sharelinkerNick
        }
    }
    
    @IBAction func ignore(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func ok(sender: AnyObject)
    {
        let newNote = noteNameField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if newNote != nil && newNote!.isEmpty == false
        {
            ServiceContainer.getService(UserService).acceptUserLink(self.linkMessage.sharelinkerId,noteName: newNote!){ isSuc in
                if isSuc
                {
                    self.navigationController?.popViewControllerAnimated(true)
                }else
                {
                    self.playToast( "ACCEPT_USER_LINK_FAILED".localizedString())
                }
            }
        }
    }
    
    static func instanceFromStoryBoard() -> LinkConfirmViewController
    {
        return instanceFromStoryBoard("UserAccount", identifier: "linkConfirmViewController",bundle: Sharelink.mainBundle()) as! LinkConfirmViewController
    }
}