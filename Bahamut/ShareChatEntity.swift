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

    @NSManaged var chatId: String
    @NSManaged var shareId: String
    @NSManaged var chatUsers: String

}
