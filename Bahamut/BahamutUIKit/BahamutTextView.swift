//
//  BahamutTextView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/1.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

class BahamutTextView: UITextView {
    
    var placeHolder:String?{
        didSet{
            placeHolderLabel?.text = placeHolder
        }
    }
    
    private(set) var placeHolderLabel:UILabel?{
        didSet{
            placeHolderLabel?.text = placeHolder
            placeHolderLabel?.hidden = !String.isNullOrEmpty(text)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BahamutTextView.onTextChanged(_:)), name: UITextViewTextDidChangeNotification, object: self)
        }
    }
    
    override var text: String!{
        didSet{
            placeHolderLabel?.hidden = !String.isNullOrEmpty(text)
        }
    }
    
    func onTextChanged(a:NSNotification) {
        placeHolderLabel?.hidden = !String.isNullOrEmpty(text)
    }
    
    var placeHolderTextAlign:NSTextAlignment = .Left{
        didSet{
            placeHolderLabel?.textAlignment = placeHolderTextAlign
        }
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if placeHolderLabel == nil {
            self.enablesReturnKeyAutomatically = true
            placeHolderLabel = UILabel()
            placeHolderLabel?.textColor = UIColor.lightGrayColor()
            self.addSubview(placeHolderLabel!)
        }
        placeHolderLabel?.textAlignment = placeHolderTextAlign
        placeHolderLabel?.font = self.font
        placeHolderLabel?.text = placeHolder
        placeHolderLabel?.frame = CGRectMake(6, 6, self.bounds.size.width - 12, self.bounds.size.height - 12)
    }
}
