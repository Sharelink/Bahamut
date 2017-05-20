//
//  PaddingLabel.swift
//  aivigi
//
//  Created by Alex Chow on 2017/5/13.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

class PaddingLabel: UILabel {
    var padding:UIEdgeInsets!
    override func drawText(in rect: CGRect) {
        if let pd = padding{
            let newRect = UIEdgeInsetsInsetRect(rect, pd)
            super.drawText(in: newRect)
        }else{
            super.drawText(in: rect)
        }
        
    }
    
    override var intrinsicContentSize: CGSize{
        var size = super.intrinsicContentSize
        if let pd = self.padding{
            size.height += pd.top + pd.bottom
            size.width += pd.left + pd.right
        }
        return size
    }
}
