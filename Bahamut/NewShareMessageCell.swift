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
    static var messageLenghtLimit = 1024
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
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty && range.length > 0 {
            return true
        }else {
            if textView.text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) - range.length + text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > NewShareMessageCell.messageLenghtLimit {
                self.rootController.showToast("MSG_IS_TOO_LONG".localizedString())
                return false
            }
            else {
                return true
            }
        }
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
        self.shareMessageTextView.text = rootController.passedShareModel.message
        updateMsgTxtPlaceHolder()
    }
    
    override func initCell(){
        if isReshare
        {
            initReshareMessageCell()
        }
    }
}