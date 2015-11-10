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
        }
    }
    
    var url:String!{
        didSet{
            if url != nil
            {
                webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
            }
        }
    }
    
    //"SimpleBrowser"
    static func openUrl(currentViewController:UIViewController,url:String)
    {
        let controller = instanceFromStoryBoard()
        if let nvController = currentViewController.navigationController
        {
            nvController.pushViewController(controller, animated: true)
            controller.url = url;
        }
    }
    
    static func instanceFromStoryBoard() -> SimpleBrowser
    {
        return instanceFromStoryBoard("Component", identifier: "SimpleBrowser") as! SimpleBrowser
    }
}