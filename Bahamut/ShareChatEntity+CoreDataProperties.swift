//
//  ShareChatEntity+CoreDataProperties.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/11.
//  Copyright © 2015年 GStudio. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ShareChatEntity {

    func addUser(userId:String)
    {
        if (chatUsers.containsString("userId")) == true
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
