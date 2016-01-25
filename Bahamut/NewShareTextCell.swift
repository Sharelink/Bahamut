//
//  NewShareTextCell.swift
//  Bahamut
//
//  Created by AlexChow on 15/12/14.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

class NewShareTextCell: ShareContentCellBase {
    static let reuseableId = "NewShareTextCell"
    
    override func getCellHeight() -> CGFloat {
        return 0
    }
    
    override func share(baseShareModel: ShareThing, themes: [SharelinkTheme]) -> Bool {
        if String.isNullOrWhiteSpace(rootController.shareMessageCell.shareMessage)
        {
            self.rootController.shareMessageCell.shakeAnimationForView(7)
            return false
        }else
        {
            let filmModel = FilmModel()
            filmModel.film = FilmAssetsConstants.SharelinkFilm
            let shareContent = filmModel.toJsonString()
            baseShareModel.shareType = ShareThingType.shareText.rawValue
            baseShareModel.shareContent = shareContent
            shareService.postNewShare(baseShareModel, tags: themes) { (shareId) -> Void in
                if shareId != nil
                {
                    self.shareService.postNewShareFinish(shareId, isCompleted: true, callback: { (isSuc) -> Void in
                        if isSuc
                        {
                            self.rootController.showCheckMark("SHARE_SUCCESSED".localizedString())
                        }else
                        {
                            self.rootController.showCrossMark("POST_SHARE_FAILED".localizedString())
                        }
                    })
                }else{
                    self.rootController.showCrossMark("POST_SHARE_FAILED".localizedString())
                }
            }
            self.rootController.showCheckMark("SHARING".localizedString())
            return true
        }
    }
}
