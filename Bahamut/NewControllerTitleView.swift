//
//  NewControllerTitleView.swift
//  Bahamut
//
//  Created by AlexChow on 16/1/4.
//  Copyright © 2016年 GStudio. All rights reserved.
//
import UIKit

class NewControllerTitleView: UIView {

    var shareQueue:Int = 0{
        didSet{
            if indicator != nil{
                self.updateIndicator()
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = NSLocalizedString("NEW_SHARE_TITLE", comment: "")
            self.backgroundColor = UIColor.clearColor()
        }
    }
    @IBOutlet weak var indicator: UIActivityIndicatorView!{
        didSet{
            indicator.hidesWhenStopped = true
            updateIndicator()
        }
    }
    
    private func updateIndicator()
    {
        if shareQueue > 0
        {
            indicator.startAnimating()
            indicator.hidden = false
        }else
        {
            indicator.stopAnimating()
        }
    }
    
    static func instanceFromXib() -> NewControllerTitleView
    {
        return NSBundle.mainBundle().loadNibNamed("UIViews", owner: nil, options: nil).filter{$0 is NewControllerTitleView}.first as! NewControllerTitleView
    }
}
