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

    @NSManaged var newMessage: NSNumber
    @NSManaged var chatId: String
    @NSManaged var shareId: String
    @NSManaged var chatUsers: String

}
