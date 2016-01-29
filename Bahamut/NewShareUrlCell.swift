//
//  NewShareUrlCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/13.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import Alamofire

class NewShareUrlCell: ShareContentCellBase,UITextFieldDelegate{

    static let reuseableId = "NewShareUrlCell"
    
    override func getCellHeight() -> CGFloat {
        if isReshare
        {
            return 77
        }
        return 128
    }
    
    //private var titleLoaded = false
    private var urlModel:UrlContentModel!
    @IBOutlet weak var pasteButton: UIButton!
    @IBOutlet weak var clearUrlButton: UIButton!
    
    @IBOutlet weak var getTitleIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shareUrl: UITextField!{
        didSet{
            shareUrl.delegate = self
        }
    }
    
    @IBAction func clearUrl(sender: AnyObject) {
        clear()
    }
    @IBAction func pasteUrl(sender: AnyObject) {
        if let url = UIPasteboard.generalPasteboard().URL{
            self.shareUrl.text = url.absoluteString
            self.prepareShare()
        }else
        {
            self.rootController.showToast("NO_URL_IN_PASTE_BOARD".localizedString())
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if String.isNullOrWhiteSpace(textField.text)
        {
            textField.text = "http://"
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        prepareShare()
    }
    
    private func prepareShare()
    {
        if String.isNullOrWhiteSpace(shareUrl.text)
        {
            shareUrl.text = ""
        }else if shareUrl.text! =~ urlRegex
        {
            loadHtml(shareUrl.text!)
        }
    }

    private func loadHtml(url:String){
        urlModel = nil
        self.getTitleIndicator.hidden = false
        self.getTitleIndicator.startAnimating()
        Alamofire.request(.GET, url).responseString { (result) -> Void in
            self.getTitleIndicator.stopAnimating()
            self.getTitleIndicator.hidden = true
            if result.result.isSuccess{
                if let htmlString = result.result.value{
                    let title = ""
                    self.titleLabel.text = title
                    let begin = htmlString.rangeOfString("<title>", options: [.CaseInsensitiveSearch], range: nil, locale: nil)
                    let end = htmlString.rangeOfString("</title>", options: [.CaseInsensitiveSearch], range: nil, locale: nil)
                    let startIndex = begin?.last?.advancedBy(1)
                    let endIndex = end?.first
                    if startIndex != nil && endIndex != nil{
                        let title = htmlString.substringWithRange(startIndex!, endIndex: endIndex!)
                        self.titleLabel.text = title
                        self.urlModel = UrlContentModel()
                        self.urlModel.url = self.shareUrl.text
                        self.urlModel.title = self.titleLabel.text
                        return
                    }
                }
                self.titleLabel.text = "LOAD_URL_TITLE_ERROR".localizedString()
            }
        }
    }
    
    let urlRegex = "\\bhttps?://[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?"
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {

        if String.isNullOrWhiteSpace(shareUrl.text)
        {
            self.rootController.showToast("LINK_CANT_NULL".localizedString())
            return false
        }else if shareUrl.text! =~ urlRegex
        {
            if urlModel == nil
            {
                self.rootController.showToast("LINK_URL_NOT_READY".localizedString())
                return false
            }
            let shareContent = urlModel.toJsonString()
            baseShareModel.shareType = ShareThingType.shareUrl.rawValue
            baseShareModel.shareContent = shareContent
            shareService.postNewShare(baseShareModel, tags: themes) { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true, callback: { (isSuc) -> Void in
                        if isSuc
                        {
                            self.rootController.showCheckMark("SHARE_URL_SUCCESS".localizedString())
                        }else
                        {
                            self.rootController.showCrossMark("SHARE_URL_ERROR".localizedString())
                        }
                    })
                }else{
                    self.rootController.showCrossMark("SHARE_URL_ERROR".localizedString())
                }
            }
            self.rootController.showCheckMark("SHARING".localizedString())
            return true
        }
        else{
            self.rootController.showToast("INVALID_URL".localizedString())
            return false
        }
    }
    
    override func initCell() {
        self.shareUrl.text = ""
        clear()
        if let model = rootController.passedShareModel
        {
            let urlModel = UrlContentModel(json: model.shareContent)
            self.shareUrl.text = urlModel.url
            self.shareUrl.enabled = false
            self.pasteButton.hidden = true
            self.clearUrlButton.hidden = true
            self.titleLabel.text = urlModel.title
            self.titleLabel.hidden = false
            self.getTitleIndicator.hidden = true
        }
    }
    
    override func clear() {
        self.shareUrl.text = ""
        self.titleLabel.text = " "
        self.urlModel = nil
        self.getTitleIndicator.hidden = true
    }
    
}
