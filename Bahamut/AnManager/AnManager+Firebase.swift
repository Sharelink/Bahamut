//
//  AnManager+Firebase.swift
//  Slapit
//
//  Created by Alex Chow on 2017/6/17.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

//Install framework with podfile: pod 'Firebase/Core'
//Download GoogleService-Info.plist from firebase console website and add to project

import Foundation
import Firebase
extension AnManager{
    func configureFirebase() {
        FirebaseApp.configure()
    }
    
    func firebaseEvent(event:String,parameters:[String : Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }
}
