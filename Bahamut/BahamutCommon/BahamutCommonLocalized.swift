//
//  BahamutCommonLocalized.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

let BahamutCommonLocalizedTableName = "BahamutCommonLocalized"
extension String{
    var bahamutCommonLocalizedString:String{
        return LocalizedString(self, tableName: BahamutCommonLocalizedTableName, bundle: NSBundle.mainBundle())
    }
}
