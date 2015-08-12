//
//  TestStringHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
class TestStringHelper
{
    static func isRegularUserName(userName:String!) -> (isRegular: Bool, message: String)
    {
        
        if userName == nil || userName!.isEmpty
        {
            return (false,"userName can't be empty")
        }else if count(userName!) < 4 || count(userName!) > 20
        {
            return (false,"userName length must be 4 to 20")
        }
        else
        {
            return (true,"userName is regular")
        }
    }

    static func isRegularPassword(password:String!) -> (isRegular: Bool, message: String)
    {
        if password == nil || password!.isEmpty
        {
            return (false,"password can't be empty")
        }else
        {
            return (true,"password is regular")
        }
    }
    
    static func isRegularMobile(mobileNumber:String) -> Bool
    {
        return true
    }
    
    static func isRegularEmail(emailAddress:String) -> Bool
    {
        return true
    }
}
