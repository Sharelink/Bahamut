//
//  TableViewEx.swift
//  Vessage
//
//  Created by Alex Chow on 2017/3/30.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell{
    func setSeparatorFullWidth() {
        self.preservesSuperviewLayoutMargins = false
        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
    }
}



extension UITableView{
    func autoRowHeight() {
        self.estimatedRowHeight = self.rowHeight
        self.rowHeight = UITableViewAutomaticDimension
    }
}
