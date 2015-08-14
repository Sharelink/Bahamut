//
//  NewShareViewController.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/12.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import UIKit

class NewShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var shareDescriptionTextArea: UITextView!
    @IBOutlet weak var shareContentContainer: UIShareContent!

    struct SegueIdentifierConstants
    {
        static let RecordVideo = "RecordVideo"
        static let SelectVideo = "SelectVideo"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier!
        {
            case SegueIdentifierConstants.RecordVideo :
            let cameraController = segue.destinationViewController as! UICameraViewController
            cameraController.filePath = ServiceContainer.getService(FileService).createLocalStoreFileName(FileType.Video)
        default:break
        }
    }
    
    @IBAction func recordVideo() {
        performSegueWithIdentifier(SegueIdentifierConstants.RecordVideo, sender: self)
    }
    
    @IBAction func share()
    {
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
