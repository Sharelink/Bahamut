//
//  ShareChatEntity.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/11.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData


class ShareChatEntity: NSManagedObject {

    func addUser(userId:String)
    {
        if (chatUsers.containsString("\(userId)")) == true
        {
            return
        }
        chatUsers.appendContentsOf("\(userId);")
    }
    
    func removeUser(userId:String)
    {
        chatUsers = chatUsers.stringByReplacingOccurrencesOfString("\(userId);", withString: "")
    }
    
    func getUsers() -> [String]
    {
        let list = chatUsers.split(";")
        return list.filter{String.isNullOrWhiteSpace($0) == false}
    }
    

}
