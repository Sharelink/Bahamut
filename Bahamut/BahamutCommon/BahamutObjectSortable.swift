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
    func isOrderedBefore(_ b:Sortable) -> Bool
    {
        return false
    }
}

class SortableObjectList<T:Sortable>
{
    fileprivate(set) var list:[T] = [T]()
    init(initList:[T])
    {
        setSortableItems(initList)
    }
    
    fileprivate func sort()
    {
        let newList = list.sorted { (a,b) -> Bool in
            a.isOrderedBefore(b)
        }
        list = newList
    }
    
    func setSortableItems(_ items:[T]!)
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
    
    fileprivate func setSortableItem(_ item:T)
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
        list.insert(item, at: 0)
        item.saveModel()
    }
    
    func getSortedObjects(_ startIndex:Int,pageNum:Int) -> [T]
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
