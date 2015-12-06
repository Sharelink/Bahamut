//
//  DateHelper.swift
//  SharelinkSDK
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

public extension NSDate
{
    func addYears(years:Int) -> NSDate
    {
        return addDays(years * 365)
    }
    
    func addMonthes(monthes:Int) -> NSDate
    {
        return addDays(monthes * 30)
    }
    
    func addWeeks(weeks:Int) -> NSDate
    {
        return addDays(weeks * 7)
    }
    
    func addDays(days:Int) -> NSDate
    {
        return addHours(days * 24)
    }
    
    func addHours(hours:Int) -> NSDate
    {
        return self.addMinutes(hours * 60)
    }
    
    func addMinutes(minutes:Int) -> NSDate
    {
        return self.addSeconds(NSTimeInterval(minutes * 60))
    }
    
    func addSeconds(seconds:NSTimeInterval) -> NSDate
    {
        let copy = NSDate(timeIntervalSinceNow: self.timeIntervalSinceNow)
        return copy.dateByAddingTimeInterval(seconds)
    }
}

public extension NSDate
{
    public func toFriendlyString(formatter:NSDateFormatter! = nil) -> String
    {
        let interval = -self.timeIntervalSinceNow
        if interval < 60
        {
            return NSLocalizedString("JUST_NOW", comment: "new")
        }
        else if interval < 3600
        {
            return String(format: NSLocalizedString("X_MINUTES_AGO", comment: "%@ minutes ago"),"\(Int(interval/60))")
        }else if interval < 3600 * 24
        {
            return String(format: NSLocalizedString("X_HOURS_AGO", comment: "%@ hours ago"),"\(Int(interval/3600))")
        }else if interval < 3600 * 24 * 7
        {
            return String(format: NSLocalizedString("X_DAYS_AGO", comment: "%@ days ago"),"\(Int(interval/3600/24))")
        }else if formatter == nil
        {
            return self.toLocalDateString()
        }else
        {
            return formatter.stringFromDate(self)
        }
    }
}

public class DateHelper
{
    
    private static let accurateDateTimeFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()
    
    private static let dateFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
        }()
    
    private static let dateTimeFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()
    
    private static let localDateTimeFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone()
        return formatter
        }()
    
    private static let localDateFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = NSTimeZone()
        return formatter
        }()
    
    public class func toDateString(date:NSDate) -> String
    {
        return dateFomatter.stringFromDate(date)
    }
    
    public class func toAccurateDateTimeString(date:NSDate) -> String
    {
        return accurateDateTimeFomatter.stringFromDate(date)
    }
    
    public class func toDateTimeString(date:NSDate) -> String
    {
        return dateTimeFomatter.stringFromDate(date)
    }
    
    public class func stringToAccurateDate(accurateDateString:String!) -> NSDate!
    {
        if let d = accurateDateString
        {
            return accurateDateTimeFomatter.dateFromString(d)
        }
        return nil
    }
    
    public class func stringToDateTime(date:String!) -> NSDate!
    {
        if let d = date
        {
            return dateTimeFomatter.dateFromString(d)
        }
        return nil
    }
    
    public class func stringToDate(date:String!) -> NSDate!
    {
        if let d = date
        {
            return dateFomatter.dateFromString(d)
        }
        return nil
    }
    
    public class func toLocalDateTimeString(date:NSDate) -> String
    {
        return localDateTimeFomatter.stringFromDate(date)
    }
    
    public class func toLocalDateString(date:NSDate) -> String
    {
        return localDateFomatter.stringFromDate(date)
    }
    
}

public extension String
{
    public var dateTimeOfString:NSDate!{
        return DateHelper.stringToDateTime(self)
    }
    
    public var dateTimeOfAccurateString:NSDate!{
        return DateHelper.stringToAccurateDate(self)
    }
}

public extension NSDate
{
    public func toDateString() -> String
    {
        return DateHelper.toDateString(self)
    }
    
    public func toDateTimeString() -> String
    {
        return DateHelper.toDateTimeString(self)
    }
    
    public func toAccurateDateTimeString() -> String
    {
        return DateHelper.toAccurateDateTimeString(self)
    }
    
    public func toLocalDateString() -> String
    {
        return DateHelper.toLocalDateString(self)
    }
    
    public func toLocalDateTimeString() -> String
    {
        return DateHelper.toLocalDateTimeString(self)
    }
}