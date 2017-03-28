//
//  DateHelper.swift
//  BahamutRFKit
//
//  Created by AlexChow on 15/8/8.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

open class DateHelper
{
    open static var UnixTimeSpanTotalMilliseconds:Int64{
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    fileprivate static let accurateDateTimeFomatter:DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    fileprivate static let dateFomatter:DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
        }()
    
    fileprivate static let dateTimeFomatter:DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    fileprivate static let localDateTimeSimpleFomatter:DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    fileprivate static let localDateTimeFomatter:DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
        }()
    
    fileprivate static let localDateFomatter:DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
        }()
    
    open class func toDateString(_ date:Date) -> String
    {
        return dateFomatter.string(from: date)
    }
    
    open class func toAccurateDateTimeString(_ date:Date) -> String
    {
        return accurateDateTimeFomatter.string(from: date)
    }
    
    open class func toDateTimeString(_ date:Date) -> String
    {
        return dateTimeFomatter.string(from: date)
    }
    
    open class func stringToAccurateDate(_ accurateDateString:String!) -> Date!
    {
        if let d = accurateDateString
        {
            return accurateDateTimeFomatter.date(from: d)
        }
        return nil
    }
    
    open class func stringToDateTime(_ date:String!) -> Date!
    {
        if let d = date
        {
            return dateTimeFomatter.date(from: d)
        }
        return nil
    }
    
    open class func stringToDate(_ date:String!) -> Date!
    {
        if let d = date
        {
            return dateFomatter.date(from: d)
        }
        return nil
    }
    
    open class func toLocalDateTimeSimpleString(_ date:Date) -> String
    {
        return localDateTimeSimpleFomatter.string(from: date)
    }
    
    open class func toLocalDateTimeString(_ date:Date) -> String
    {
        return localDateTimeFomatter.string(from: date)
    }
    
    open class func toLocalDateString(_ date:Date) -> String
    {
        return localDateFomatter.string(from: date)
    }
    
    static let monthDays = [31,28,31,30,31,30,31,31,30,31,30,31]
    open class func daysOfMonth(_ year:Int,month:Int) -> Int
    {
        let monthIndex = month > 0 ? month - 1 : 0
        if monthIndex == 1
        {
            return monthDays[monthIndex] + (isLeapYear(year) ? 1 : 0)
        }
        return monthDays[monthIndex]
    }
    
    open class func isLeapYear(_ year:Int) -> Bool
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
    public var dateTimeOfString:Date!{
        return DateHelper.stringToDateTime(self)
    }
    
    public var dateTimeOfAccurateString:Date!{
        return DateHelper.stringToAccurateDate(self)
    }
}

public extension Date
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

public extension Date
{
    var totalSecondsSince1970:NSNumber{
        return NSNumber(value: timeIntervalSince1970 as Double)
    }
    
    var totalMinutesSince1970:NSNumber{
        return NSNumber(value:totalSecondsSince1970.doubleValue / 60.0)
    }
    
    var totalHoursSince1970:NSNumber{
        return NSNumber(value:totalMinutesSince1970.doubleValue / 60)
    }
    
    var totalDaysSince1970:NSNumber{
        return NSNumber(value:totalHoursSince1970.doubleValue / 24)
    }
    
    var totalSecondsSinceNow:NSNumber{
        return NSNumber(value: timeIntervalSinceNow as Double)
    }
    
    var totalMinutesSinceNow:NSNumber{
        return NSNumber(value:totalSecondsSinceNow.doubleValue / 60)
    }
    
    var totalHoursSinceNow:NSNumber{
        return NSNumber(value:totalMinutesSinceNow.doubleValue / 60)
    }
    
    var totalDaysSinceNow:NSNumber{
        return NSNumber(value:totalHoursSinceNow.doubleValue / 24)
    }
}

public extension Date
{
    func addYears(_ years:Int) -> Date
    {
        return addDays(years * 365)
    }
    
    func addMonthes(_ monthes:Int) -> Date
    {
        return addDays(monthes * 30)
    }
    
    func addWeeks(_ weeks:Int) -> Date
    {
        return addDays(weeks * 7)
    }
    
    func addDays(_ days:Int) -> Date
    {
        return addHours(days * 24)
    }
    
    func addHours(_ hours:Int) -> Date
    {
        return self.addMinutes(hours * 60)
    }
    
    func addMinutes(_ minutes:Int) -> Date
    {
        return self.addSeconds(TimeInterval(minutes * 60))
    }
    
    func addSeconds(_ seconds:TimeInterval) -> Date
    {
        let copy = Date(timeIntervalSinceNow: self.timeIntervalSinceNow)
        return copy.addingTimeInterval(seconds)
    }
}

public extension Date
{
    public func isAfter(_ date:Date) -> Bool
    {
        return self.timeIntervalSince1970 > date.timeIntervalSince1970
    }
    
    public func ge(_ date:Date) -> Bool
    {
        return self.timeIntervalSince1970 >= date.timeIntervalSince1970
    }
    
    public func isBefore(_ date:Date) -> Bool
    {
        return self.timeIntervalSince1970 < date.timeIntervalSince1970
    }
    
    public func le(_ date:Date) -> Bool
    {
        return self.timeIntervalSince1970 <= date.timeIntervalSince1970
    }
}

public extension Date
{
    public func toFriendlyString(_ formatter:DateFormatter! = nil) -> String
    {
        let interval = -self.timeIntervalSinceNow
        if interval < 60
        {
            return "JUST_NOW".bahamutCommonLocalizedString
        }
        else if interval < 3600
        {
            let mins = String(format: "%.0f", abs(self.totalMinutesSinceNow.doubleValue))
            return String(format:"X_MINUTES_AGO".bahamutCommonLocalizedString,mins)
        }else if interval < 3600 * 24
        {
            let hours = String(format: "%.0f", abs(self.totalHoursSinceNow.doubleValue))
            return String(format:"X_HOURS_AGO".bahamutCommonLocalizedString,hours)
        }else if interval < 3600 * 24 * 7
        {
            let days = String(format: "%.0f", abs(self.totalDaysSinceNow.doubleValue))
            return String(format:"X_DAYS_AGO".bahamutCommonLocalizedString,days)
        }else if formatter == nil
        {
            return self.toLocalDateString()
        }else
        {
            return formatter.string(from: self)
        }
    }
}

extension DateHelper
{
    static func generateDate(_ year:Int = 1970,month:Int = 1,day:Int = 1,hour:Int = 0,minute:Int = 0, second:TimeInterval = 0) -> Date
    {
        var s = second
        var M = month
        var m = minute
        var d = day
        var h = hour
        if hour < 0 || hour > 23{
            h = 0
        }
        if minute > 60 || minute < 0  {
            m = 0
        }
        if second > 60 || second < 0
        {
            s = 0
        }
        if month <= 0 || month > 12
        {
            M = 1
        }
        if day <= 0
        {
            d = 1
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        let dateString = String(format: "%04d-%02d-%02d %02d:%02d:%06.3f", year,M,d,h,m,s)
        return formatter.date(from: dateString)!
    }
}

public extension Date
{
    var hourOfDate:Int{
        return currentTimeZoneComponents.hour!
    }
    
    var minuteOfDate:Int{
        return currentTimeZoneComponents.minute!
    }
    
    var secondOfDate:Int{
        return currentTimeZoneComponents.second!
    }
    
    var yearOfDate:Int{
        return currentTimeZoneComponents.year!
    }
    
    var monthOfDate:Int{
        return currentTimeZoneComponents.month!
    }
    
    var dayOfDate:Int{
        return currentTimeZoneComponents.day!
    }
    
    var weekDayOfDate:Int{
        return currentTimeZoneComponents.weekday!
    }
    
    var shortWeekdayOfDate:String{
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEE"
        let timeStr = formatter.string(from: self)
        return timeStr
    }
    
    var weekdayOfDate:String{
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEEE"
        let timeStr = formatter.string(from: self)
        return timeStr
    }
    
    var currentTimeZoneComponents:DateComponents
    {
        return Calendar.autoupdatingCurrent.dateComponents(in: TimeZone.current, from: self)
    }
}

