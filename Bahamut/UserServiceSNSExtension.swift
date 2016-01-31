//
//  UserServiceSNDExtension.swift
//  Sharelink
//
//  Created by AlexChow on 16/1/29.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

extension DateHelper
{
    static func isInNewYearVocation()->Bool{
        let now = NSDate()
        let newYearStartTime = DateHelper.generateDate(2016, month: 2, day: 7, hour: 0, minute: 0, second: 0)
        let lastNewYearVacation = DateHelper.generateDate(2016, month: 2, day: 23, hour: 0, minute: 0, second: 0)
        if now.timeIntervalSince1970 > newYearStartTime.timeIntervalSince1970 && now.timeIntervalSince1970 < lastNewYearVacation.timeIntervalSince1970
        {
            return true
        }else
        {
            return false
        }
    }
}

extension UserService
{
    
    #if APP_VERSION
    
    func getLinkMessageContent() -> ISSContent
    {
        let userService = ServiceContainer.getService(UserService)
        let user = userService.myUserModel
        let userHeadIconPath = PersistentManager.sharedInstance.getImageFilePath(user.avatarId)
        
        var contentMsg = String(format: "ASK_LINK_MSG".localizedString(),user.nickName)
        if DateHelper.isInNewYearVocation()
        {
            contentMsg = String(format: "ASK_LINK_MSG_NEW_YEAR".localizedString(),user.nickName)
        }
        
        let title = "Sharelink"
        
        let linkMeCmd = userService.generateSharelinkLinkMeCmd()
        let url = "\(SharelinkConfig.bahamutConfig.sharelinkOuterExecutorUrlPrefix)\(linkMeCmd)"
        
        let contentWithUrl = "\(contentMsg)\n\(url)"
        
        var img:ISSCAttachment!
        if let qrImage = QRCode.generateImage(url, avatarImage: nil)
        {
            let imgData = UIImageJPEGRepresentation(qrImage, 1.0)
            img = ShareSDK.imageWithData(imgData, fileName: nil, mimeType: nil)
        }
        if img == nil
        {
            img = ShareSDK.imageWithPath(userHeadIconPath ?? ImageAssetsConstants.defaultAvatarPath)
        }
        let publishContent = ShareSDK.content(contentWithUrl, defaultContent: nil, image: img, title: title, url: url, description: nil, mediaType: SSPublishContentMediaTypeImage)
        
        publishContent.addWeixinSessionUnitWithType(5, content: contentMsg, title: title, url: url, thumbImage: nil, image: img, musicFileUrl: nil, extInfo: nil, fileData: nil, emoticonData: nil)
        
        publishContent.addWeixinTimelineUnitWithType(5, content: contentMsg, title: title, url: url, thumbImage: nil, image: img, musicFileUrl: nil, extInfo: nil, fileData: nil, emoticonData: nil)
        
        publishContent.addQQUnitWithType(3, content: contentMsg, title: title, url: url, image: img)
        
        publishContent.addSMSUnitWithContent(contentWithUrl)
        
        publishContent.addFacebookWithContent(contentWithUrl, image: img)
        
        publishContent.addMailUnitWithSubject(title, content: contentWithUrl, isHTML: false, attachments: nil, to: nil, cc: nil, bcc: nil)
        
        publishContent.addWhatsAppUnitWithContent(contentWithUrl, image: img, music: nil, video: nil)
        
        return publishContent
    }
    
    func shareAddLinkMessageToSNS(viewController:UIViewController)
    {
        
        let publishContent = getLinkMessageContent()
        let container = ShareSDK.container()

        container.setIPadContainerWithView(viewController.view, arrowDirect: .Down)
        container.setIPhoneContainerWithViewController(viewController)
        ShareSDK.showShareActionSheet(container, shareList: nil, content: publishContent, statusBarTips: true, authOptions: nil, shareOptions: nil) { (type, state, statusInfo, error, end) -> Void in
            if (state == SSResponseStateSuccess)
            {
                viewController.playToast( "SHARE_SUC".localizedString())
            }
            else if (state == SSResponseStateFail)
            {
                viewController.playToast( "SHARE_FAILED".localizedString())
                NSLog("share fail:%ld,description:%@", error.errorCode(), error.errorDescription());
            }
        }
    }
    #endif
}