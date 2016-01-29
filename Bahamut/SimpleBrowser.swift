//
//  Browser.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/30.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class SimpleBrowser: UIViewController,UIWebViewDelegate
{
    @IBOutlet weak var webView: UIWebView!{
        didSet{
            webView.delegate = self
            if url != nil{
                loadUrl()
            }
        }
    }
    
    var url:String!{
        didSet{
            if url != nil && webView != nil
            {
                loadUrl()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func back(sender: AnyObject)
    {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func loadUrl()
    {
        webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
    }
    
    //"SimpleBrowser"
    static func openUrl(currentViewController:UINavigationController,url:String)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let controller = instanceFromStoryBoard()
            let navController = UINavigationController(rootViewController: controller)
            navController.navigationBar.barStyle = currentViewController.navigationBar.barStyle
            navController.changeNavigationBarColor()
            currentViewController.presentViewController(navController, animated: true, completion: {
                controller.url = url;
            })
        }
    }
    
    static func instanceFromStoryBoard() -> SimpleBrowser
    {
        return instanceFromStoryBoard("Component", identifier: "SimpleBrowser",bundle: Sharelink.mainBundle()) as! SimpleBrowser
    }
}