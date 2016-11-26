//
//  CommonExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

func isInSimulator() -> Bool{
    return TARGET_IPHONE_SIMULATOR == Int32("1")
}
