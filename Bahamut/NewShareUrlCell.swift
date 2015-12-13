//
//  NewShareUrlCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/13.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class NewShareUrlCell: ShareContentCellBase{

    static let reuseId = "NewShareUrlCell"
    
    @IBOutlet weak var shareUrl: UITextView!
    
    @IBAction func pasteUrl(sender: AnyObject) {
        if let url = UIPasteboard.generalPasteboard().URL{
            shareUrl.text = url.absoluteString
        }else
        {
            self.rootController.showToast(NSLocalizedString("NO_URL_IN_PASTE_BOARD", comment: ""))
        }
    }
    
    private func getShareContent() -> String? {
        let urlModel = UrlContentModel()
        if String.isNullOrWhiteSpace(shareUrl.text)
        {
            urlModel.url = ""
        }else{
            urlModel.url = shareUrl.text
        }
        return urlModel.toJsonString()
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> (canShare: Bool, msg: String?) {
        baseShareModel.shareType = ShareThingType.shareUrl.rawValue
        baseShareModel.shareContent = getShareContent()
        shareService.postNewShare(baseShareModel, tags: themes) { (shareId) -> Void in
            if shareId != nil
            {
                self.shareService.postNewShareFinish(shareId, isCompleted: true, callback: { (isSuc) -> Void in
                    let msg = isSuc ? NSLocalizedString("SHARE_URL_SUCCESS", comment: "") : NSLocalizedString("SHARE_URL_ERROR", comment: "")
                    self.rootController.showToast(msg)
                })
            }else{
                self.rootController.showToast(NSLocalizedString("SHARE_URL_ERROR", comment: ""))
            }
        }
        return (true,nil)
    }
    
    override func initCell() {
        self.shareUrl.text = ""
        if isReshare
        {
            let urlModel = UrlContentModel(json: rootController.reShareModel.shareContent)
            self.shareUrl.text = urlModel.url
        }
    }
    
    override func clear() {
        self.shareUrl.text = ""
    }
    
}
