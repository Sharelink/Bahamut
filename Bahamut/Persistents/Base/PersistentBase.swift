//
//  PersistentExtensionBase.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/9.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation

protocol PersistentExtensionProtocol
{
    func resetExtension()
    func releaseExtension()
    func destroyExtension()
    func storeImmediately()
}

protocol PersistentUpdateProtocol
{
    func update(obj:AnyObject?)
}