//
//  ProfileViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/7/28.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController
{
    

    private struct Constants{
        static let SegueNextToInformation:String = "Next To Information"
    }
    @IBOutlet weak var nickNameTextfield: UITextField!
    @IBOutlet weak var saveProfileButton: UIButton!
    @IBOutlet weak var profileVideoView:UIView!{
        didSet{
            
        }
    }
    @IBOutlet weak var headIconImage: UIImageView!{
        didSet{
            headIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "takeHeadIconPhoto:"))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func initProfileVideoPlayer()
    {
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func saveProfile()
    {
    }

    
    func captureProfileVideo(_:UIGestureRecognizer! = nil)
    {
        print("captureProfileVideo()")
    }
    
    func takeHeadIconPhoto(_:UIGestureRecognizer! = nil)
    {
        print("takeHeadIconPhoto()")
    }
}