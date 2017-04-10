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
    
    fileprivate(set) var placeHolderLabel:UILabel?{
        didSet{
            placeHolderLabel?.text = placeHolder
            placeHolderLabel?.isHidden = !String.isNullOrEmpty(text)
            placeHolderLabel?.numberOfLines = 0
            NotificationCenter.default.addObserver(self, selector: #selector(BahamutTextView.onTextChanged(_:)), name: NSNotification.Name.UITextViewTextDidChange, object: self)
        }
    }
    
    override var text: String!{
        didSet{
            placeHolderLabel?.isHidden = !String.isNullOrEmpty(text)
        }
    }
    
    func onTextChanged(_ a:Notification) {
        placeHolderLabel?.isHidden = !String.isNullOrEmpty(text)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var placeHolderTextAlign:NSTextAlignment = .left{
        didSet{
            placeHolderLabel?.textAlignment = placeHolderTextAlign
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if placeHolderLabel == nil {
            self.enablesReturnKeyAutomatically = true
            placeHolderLabel = UILabel()
            placeHolderLabel?.textColor = UIColor.lightGray
            self.addSubview(placeHolderLabel!)
        }
        placeHolderLabel?.textAlignment = placeHolderTextAlign
        placeHolderLabel?.font = self.font
        placeHolderLabel?.text = placeHolder
        placeHolderLabel?.frame = CGRect(x: 6, y: 8, width: self.bounds.size.width - 12, height: self.bounds.size.height - 12)
        placeHolderLabel?.sizeToFit()
    }
}
