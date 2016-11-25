//
//  UIView+RemoveChildView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/25.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    func removeAllSubviews() {
        self.subviews.forEach{$0.removeFromSuperview()}
    }
}
