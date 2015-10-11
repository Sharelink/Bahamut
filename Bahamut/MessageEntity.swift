//
//  MessageEntity.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/11.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData


class MessageEntity: NSManagedObject {
    @NSManaged var chatId: String
    @NSManaged var isRead: NSNumber
    @NSManaged var msgData: NSData
    @NSManaged var msgId: String
    @NSManaged var senderId: String
    @NSManaged var msgText: String
    @NSManaged var type: String
    @NSManaged var time: NSDate
    @NSManaged var isSend: NSNumber
}
