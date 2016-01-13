//
//  UICollectionViewFullFlowLayout.swift
//  iDiaries
//
//  Created by AlexChow on 16/1/13.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import Foundation

class UICollectionViewFullFlowLayout: UICollectionViewFlowLayout {
    
    var maximumSpacing:CGFloat = 5
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if var answer = super.layoutAttributesForElementsInRect(rect)
        {
            var lineContentWidth:CGFloat = 0
            var avgInterval:CGFloat = 0
            let cellWidth = self.collectionViewContentSize().width
            var lineItemCount = 0
            var lineStartIndex = 0
            for i in 1..<answer.count
            {
                let currentLayoutAttributes = answer[i];
                let prevLayoutAttributes = answer[i - 1];
                let origin = CGRectGetMaxX(prevLayoutAttributes.frame);
                lineItemCount++
                if(origin + maximumSpacing + currentLayoutAttributes.frame.size.width < cellWidth) {
                    var frame = currentLayoutAttributes.frame;
                    frame.origin.x = origin + maximumSpacing;
                    currentLayoutAttributes.frame = frame;
                    lineContentWidth = frame.origin.x + frame.size.width
                    
                }else{
                    avgInterval = (cellWidth - lineContentWidth) / CGFloat(lineItemCount)
                    for index in 0..<lineItemCount
                    {
                        let realIndex = lineStartIndex + index
                        var frame = answer[realIndex].frame
                        frame.origin.x += avgInterval * CGFloat(index)
                        frame.size.width += avgInterval
                        answer[realIndex].frame = frame
                    }
                    lineItemCount = 0
                    lineStartIndex = i
                }
            }
            return answer
        }
        return nil
    }
}