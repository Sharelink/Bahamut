//
//  ADConfig.swift
//  FidgetSpinner
//
//  Created by Alex Chow on 2017/5/21.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation

class AdConfig {
    static private(set) var adConfigDict:NSDictionary!
    static func load(url:URL) {
        adConfigDict = NSDictionary(contentsOf: url)
    }
}


