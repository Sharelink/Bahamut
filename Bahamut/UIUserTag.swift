//
//  UserTag.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/17.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class UserTagCell: UICollectionViewCell
{
    var model:UserTag!{
        didSet{
            if tagNameLabel != nil
            {
                tagNameLabel.text = model.tagName
                tagNameLabel.textColor = UIColor(hexString: model.tagColor)
            }
        }
    }
    
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        super.drawLayer(layer, inContext: ctx)
        layer.cornerRadius = 6.0
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = tagNameLabel.textColor.CGColor
    }
    
    @IBOutlet weak var tagNameLabel: UILabel!
    
    func update()
    {
        tagNameLabel.text = model.tagName
        tagNameLabel.textColor = UIColor(hexString: model.tagColor)
    }
}