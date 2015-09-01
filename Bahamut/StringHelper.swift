//
//  TestStringHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

class StringHelper
{
    static func IntToLetter(letterIndex:Int) -> Character
    {
        return (Character(UnicodeScalar(letterIndex)))
    }
    
    static func IntToLetterString(letterIndex:Int) -> String
    {
        return "\(IntToLetter(letterIndex))"
    }
}
