//
//  NewShareMessageCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/11/18.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit

class NewShareMessageCell: NewShareCellBase,UITextViewDelegate
{
    static let reuseableId = "NewShareMessageCell"
    @IBOutlet weak var shareMessageTextView: UITextView!{
        didSet{
            shareMessageTextView.delegate = self
            shareMessageTextView.layer.cornerRadius = 7
            shareMessageTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
            shareMessageTextView.layer.borderWidth = 1
            shareMessageTextView.delegate = self
            updateMsgTxtPlaceHolder()
        }
    }
    @IBOutlet weak var messageTextPlaceHolder: UILabel!{
        didSet{
            updateMsgTxtPlaceHolder()
        }
    }
    
    var shareMessage:String{
        return self.shareMessageTextView.text ?? ""
    }
    
    func textViewDidChange(textView: UITextView)
    {
        updateMsgTxtPlaceHolder()
    }
    
    private func updateMsgTxtPlaceHolder()
    {
        if messageTextPlaceHolder != nil && shareMessageTextView != nil
        {
            messageTextPlaceHolder.hidden = !String.isNullOrEmpty(shareMessageTextView?.text ?? nil)
        }
    }
    
    override func clear() {
        self.shareMessageTextView.text = ""
    }
    
    private func initReshareMessageCell(){
        self.shareMessageTextView.text = rootController.reShareModel.message
        updateMsgTxtPlaceHolder()
    }
    
    override func initCell(){
        if isReshare
        {
            initReshareMessageCell()
        }
    }
}