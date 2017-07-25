//
//  ShareHelper+Firebase.swift
//  drawlinegame
//
//  Created by Alex Chow on 2017/7/19.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
extension ShareHelper{
    
    static func addLogFirebaseEvent() {
        ShareHelper.addShareObservers(observer: self, selector: #selector(ShareHelper.onLogFirebaseEvent(a:)))
    }
    
    static func onLogFirebaseEvent(a:Notification) {
        if a.name == ShareHelper.shareShown{
            AnManager.shared.firebaseEvent(event: "share", parameters: nil)
        }else if a.name == ShareHelper.shareError{
            AnManager.shared.firebaseEvent(event: "share_error")
        }else if a.name == ShareHelper.shareWithType{
            AnManager.shared.firebaseEvent(event: "share_with_type", parameters: a.userInfo as? [String : Any])
        }
    }
}
