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

    func addUser(_ userId:String)
    {
        if (chatUsers.contains("\(userId)")) == true
        {
            return
        }
        chatUsers.append("\(userId);")
    }
    
    func removeUser(_ userId:String)
    {
        chatUsers = chatUsers.replacingOccurrences(of: "\(userId);", with: "")
    }
    
    func getUsers() -> [String]
    {
        let list = chatUsers.split(";")
        return list.filter{String.isNullOrWhiteSpace($0) == false}
    }
    

}
