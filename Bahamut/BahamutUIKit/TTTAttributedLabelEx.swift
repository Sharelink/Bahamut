//
//  TTTAttributedLabelEx.swift
//  Vessage
//
//  Created by Alex Chow on 2017/4/17.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

import Foundation
import TTTAttributedLabel
extension TTTAttributedLabel{
    func setTextAndSimplifyUrl(text:String,linkHolder:String,attchLinkMark:Bool) {
        let (content,urlRanges,urls) = StringHelper.getSimplifyURLAttributeString(origin: text, urlTips: linkHolder,attchLinkMark: attchLinkMark)
        
        if let ct = content,let ranges = urlRanges,let links = urls{
            self.text = ct
            for i in 0..<min(ranges.count, links.count) {
                let _ = self.addLink(to: URL(string: links[i]), with: ranges[i])
            }
        }else{
            self.text = text
        }
    }
}
