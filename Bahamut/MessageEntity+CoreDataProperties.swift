//
//  MessageEntity+CoreDataProperties.swift
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

extension MessageEntity {
    @NSManaged var chatId: String
    @NSManaged var isRead: NSNumber
    @NSManaged var msgData: NSData
    @NSManaged var msgId: String
    @NSManaged var senderId: String
    @NSManaged var msgText: String
    @NSManaged var type: String
    @NSManaged var time: NSDate
    @NSManaged var isSend: NSNumber
    @NSManaged var sendFailed: NSNumber
}
