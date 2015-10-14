//
//  MessageEntity.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/11.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreData


class MessageEntity: NSManagedObject
{
    func isSending() -> Bool
    {
        return isSend.boolValue == false && sendFailed == false
    }
}
