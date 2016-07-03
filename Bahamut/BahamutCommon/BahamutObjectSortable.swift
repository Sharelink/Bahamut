//
//  BahamutObjectSortable.swift
//  WordClick
//
//  Created by AlexChow on 16/6/15.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation

//MARK: Sort
class Sortable : BahamutObject
{
    var compareValue:AnyObject!
    func isOrderedBefore(b:Sortable) -> Bool
    {
        return false
    }
}

class SortableObjectList<T:Sortable>
{
    private(set) var list:[T] = [T]()
    init(initList:[T])
    {
        setSortableItems(initList)
    }
    
    private func sort()
    {
        let newList = list.sort { (a,b) -> Bool in
            a.isOrderedBefore(b)
        }
        list = newList
    }
    
    func setSortableItems(items:[T]!)
    {
        if items == nil || items.count == 0
        {
            return
        }
        for item in items
        {
            self.setSortableItem(item)
        }
        self.sort()
    }
    
    private func setSortableItem(item:T)
    {
        for obj in list
        {
            if obj.getObjectUniqueIdValue() == item.getObjectUniqueIdValue()
            {
                obj.compareValue = item.compareValue
                obj.saveModel()
                return
            }
        }
        list.insert(item, atIndex: 0)
        item.saveModel()
    }
    
    func getSortedObjects(startIndex:Int,pageNum:Int) -> [T]
    {
        var result = [T]()
        let lastIndex = min(list.count,startIndex + pageNum)
        for i in startIndex ..< lastIndex
        {
            result.append(list[i])
        }
        return result
    }
}