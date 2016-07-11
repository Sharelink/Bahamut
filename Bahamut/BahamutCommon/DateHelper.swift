//
//  DateHelper.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation
let BahamutCommonLocalizedTableName = "BahamutCommonLocalized"
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
    
    private static let localDateTimeSimpleFomatter:NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yy/MM/dd HH:mm"
        formatter.timeZone = NSTimeZone()
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
    
    public class func toLocalDateTimeSimpleString(date:NSDate) -> String
    {
        return localDateTimeSimpleFomatter.stringFromDate(date)
    }
    
    public class func toLocalDateTimeString(date:NSDate) -> String
    {
        return localDateTimeFomatter.stringFromDate(date)
    }
    
    public class func toLocalDateString(date:NSDate) -> String
    {
        return localDateFomatter.stringFromDate(date)
    }
    
    static let monthDays = [31,28,31,30,31,30,31,31,30,31,30,31]
    public class func daysOfMonth(year:Int,month:Int) -> Int
    {
        let monthIndex = month > 0 ? month - 1 : 0
        if monthIndex == 1
        {
            return monthDays[monthIndex] + (isLeapYear(year) ? 1 : 0)
        }
        return monthDays[monthIndex]
    }
    
    public class func isLeapYear(year:Int) -> Bool
    {
        if (year%4==0 && year % 100 != 0) || year%400==0 {
            return true
        }else {
            return false
        }
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
    
    public func toLocalDateTimeSimpleString() -> String
    {
        return DateHelper.toLocalDateTimeSimpleString(self)
    }
}

public extension NSDate
{
    var totalSecondsSince1970:NSNumber{
        return NSNumber(double:timeIntervalSince1970)
    }
    
    var totalMinutesSince1970:NSNumber{
        return totalSecondsSince1970.doubleValue / 60
    }
    
    var totalHoursSince1970:NSNumber{
        return totalMinutesSince1970.doubleValue / 60
    }
    
    var totalDaysSince1970:NSNumber{
        return totalHoursSince1970.doubleValue / 24
    }
    
    var totalSecondsSinceNow:NSNumber{
        return NSNumber(double: timeIntervalSinceNow)
    }
    
    var totalMinutesSinceNow:NSNumber{
        return totalSecondsSinceNow.doubleValue / 60
    }
    
    var totalHoursSinceNow:NSNumber{
        return totalMinutesSinceNow.doubleValue / 60
    }
    
    var totalDaysSinceNow:NSNumber{
        return totalHoursSinceNow.doubleValue / 24
    }
}

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
    public func isAfter(date:NSDate) -> Bool
    {
        return self.timeIntervalSince1970 > date.timeIntervalSince1970
    }
    
    public func ge(date:NSDate) -> Bool
    {
        return self.timeIntervalSince1970 >= date.timeIntervalSince1970
    }
    
    public func isBefore(date:NSDate) -> Bool
    {
        return self.timeIntervalSince1970 < date.timeIntervalSince1970
    }
    
    public func le(date:NSDate) -> Bool
    {
        return self.timeIntervalSince1970 <= date.timeIntervalSince1970
    }
}

public extension NSDate
{
    public func toFriendlyString(formatter:NSDateFormatter! = nil) -> String
    {
        let interval = -self.timeIntervalSinceNow
        if interval < 60
        {
            return LocalizedString("JUST_NOW", tableName: BahamutCommonLocalizedTableName, bundle: NSBundle.mainBundle())
        }
        else if interval < 3600
        {
            let mins = String(format: "%.0f", abs(self.totalMinutesSinceNow.doubleValue))
            return String(format:LocalizedString("X_MINUTES_AGO", tableName: BahamutCommonLocalizedTableName, bundle: NSBundle.mainBundle()),mins)
        }else if interval < 3600 * 24
        {
            let hours = String(format: "%.0f", abs(self.totalHoursSinceNow.doubleValue))
            return String(format:LocalizedString("X_HOURS_AGO", tableName: BahamutCommonLocalizedTableName, bundle: NSBundle.mainBundle()),hours)
        }else if interval < 3600 * 24 * 7
        {
            let days = String(format: "%.0f", abs(self.totalDaysSinceNow.doubleValue))
            return String(format:LocalizedString("X_DAYS_AGO", tableName: BahamutCommonLocalizedTableName, bundle: NSBundle.mainBundle()),days)
        }else if formatter == nil
        {
            return self.toLocalDateString()
        }else
        {
            return formatter.stringFromDate(self)
        }
    }
}

extension DateHelper
{
    static func generateDate(year:Int = 1970,month:Int = 1,day:Int = 1,hour:Int = 0,minute:Int = 0, second:NSTimeInterval = 0) -> NSDate
    {
        var s = second
        var m = month
        var d = day
        if second > 60 || second < 0
        {
            s = 0
        }
        if month <= 0
        {
            m = 1
        }
        if day <= 0
        {
            d = 1
        }
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = NSTimeZone.systemTimeZone()
        let dateString = String(format: "%04d-%02d-%02d %02d:%02d:%06.3f", year,month,d,hour,m,s)
        return formatter.dateFromString(dateString)!
    }
}

public extension NSDate
{
    var hourOfDate:Int{
        return currentTimeZoneComponents.hour
    }
    
    var minuteOfDate:Int{
        return currentTimeZoneComponents.minute
    }
    
    var secondOfDate:Int{
        return currentTimeZoneComponents.second
    }
    
    var yearOfDate:Int{
        return currentTimeZoneComponents.year
    }
    
    var monthOfDate:Int{
        return currentTimeZoneComponents.month
    }
    
    var dayOfDate:Int{
        return currentTimeZoneComponents.day
    }
    
    var weekDayOfDate:Int{
        return currentTimeZoneComponents.weekday
    }
    
    var shortWeekdayOfDate:String{
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone()
        formatter.dateFormat = "EEE"
        let timeStr = formatter.stringFromDate(self)
        return timeStr
    }
    
    var weekdayOfDate:String{
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone()
        formatter.dateFormat = "EEEE"
        let timeStr = formatter.stringFromDate(self)
        return timeStr
    }
    
    var currentTimeZoneComponents:NSDateComponents
    {
        return NSCalendar.autoupdatingCurrentCalendar().componentsInTimeZone(NSTimeZone.systemTimeZone(), fromDate: self)
    }
}