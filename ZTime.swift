//
//  ZTime.swift
//  Zed
//
//  Created by Tor Langballe on /31/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

// http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns

import Foundation

typealias ZTime = Date
typealias ZCalendarUnit = NSCalendar.Unit

let ZLocaleEngUsPosix = "en_US_POSIX"

extension ZTime {

    static let IsoFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" // UploadFileToBucket
    static let IsoFormatWithMSecs = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    static let IsoFormatCompact = "yyyyMMdd'T'HHmmss'Z'"
    
    static let IsoFormatWithZone = "yyyy-MM-dd'T'HH:mm:ssZZZZZ" // UploadFileToBucket
    static let IsoFormatWithMSecsWithZone = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    static let IsoFormatCompactWithZone = "yyyyMMdd'T'HHmmssZZZZZ"
    
    static let CompactFormat = "yyyy-MM-dd' 'HH:mm:ss"
    static let NiceFormat = "yy-MMM-dd' 'HH:mm"
    static let HTTPHeaderDateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"

    static let minute = 60.0
    static let hour = 3600.0
    static let day = 86400.0
    
    static var Null: ZTime {
        return Date.distantPast
    }

    static var DistantFuture: ZTime {
        return Date.distantFuture
    }

    static var Now: ZTime {
        return ZTime(timeIntervalSinceNow:0)
    }
    
    init() {
        self = Date.distantPast
    }
    
    init(ztime:ZTime) {
        self.init(timeIntervalSinceReferenceDate:ztime.timeIntervalSinceReferenceDate)
    }
    
    var IsNull:Bool {
        return timeIntervalSinceReferenceDate == ZTime.Null.timeIntervalSinceReferenceDate
    }
    
    func Since() -> Double {
        return ZTime.Now - self
    }
    
    func Until() -> Double {
        return self - ZTime.Now
    }
    
    static var SecsSinceEpoc: Double {
        get { return Date.timeIntervalSinceReferenceDate }
    }
}

//func >(me: ZTime, a: ZTime) -> Bool    { return me.timeIntervalSinceReferenceDate > a.timeIntervalSinceReferenceDate }
// func <(me: ZTime, a: ZTime) -> Bool    { return me.timeIntervalSinceReferenceDate < a.timeIntervalSinceReferenceDate }
// func +=(me: inout ZTime, add:Double)   { me = ZTime(timeIntervalSinceReferenceDate:me.timeIntervalSinceReferenceDate + add)   }
//func +(me: ZTime, add:Double) -> ZTime { return ZTime(timeIntervalSinceReferenceDate:me.timeIntervalSinceReferenceDate + add) }
func -(me: ZTime, sub:ZTime) -> Double { return me.timeIntervalSinceReferenceDate - sub.timeIntervalSinceReferenceDate        }
//func -(me: ZTime, sub:Double) -> ZTime { return ZTime(timeIntervalSinceReferenceDate:me.timeIntervalSinceReferenceDate - sub) }

extension ZTime {
    enum Weekday:Int { case none = 0, mon = 1, tue, wed, thu, fri, sat, sun }
    enum Month:Int   { case none = 0, jan = 1, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec }

    init(year:Int, month:Month = .none, day:Int = -1, hour:Int = 0, minute:Int = 0, second:Int = 0, nano:Int = 0, timezone:ZTimeZone? = nil) {
        let cal = Calendar(identifier:Calendar.Identifier.gregorian)
        var comps = DateComponents()
        
        let t = ZTime.Now
        let (y, m, d, _) = t.GetGregorianDateParts(timezone:timezone)
        
        comps.year = year == -1 ? y : year
        comps.month = month == .none ? m.rawValue : month.rawValue
        comps.day = day == -1 ? d : day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        comps.nanosecond = nano
        (comps as NSDateComponents).timeZone = timezone as TimeZone?
        let date = cal.date(from: comps)
        self.init(timeIntervalSinceReferenceDate:(date?.timeIntervalSinceReferenceDate)!)
    }
    
    init?(iso8601Z:String) {
        var format = ZTime.IsoFormat
        if iso8601Z.contains(".") {
            format = ZTime.IsoFormatWithMSecs
        }
        let zone = ZTimeZone(identifier:"UTC")
        self.init(format:format, dateString:iso8601Z, locale:ZLocaleEngUsPosix, timezone:zone)
    }
    
    init?(format:String, dateString:String, locale:String = "", timezone:ZTimeZone? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        if locale == "" {
            formatter.locale = Locale.current
        } else {
            formatter.locale = Locale(identifier:locale)
        }
        if timezone != nil {
            formatter.timeZone = timezone as TimeZone!
        }
        if let date = formatter.date(from: dateString) {
            self.init(timeIntervalSinceReferenceDate:date.timeIntervalSinceReferenceDate)
        } else {
            self.init(ztime:ZTime.Null)
        }
    }
    
    func GetGregorianTimeParts(useAm:Bool = false) -> (Int,Int,Int,Int,Bool) { // hour, min, sec, nano, isam
        let cal = Calendar(identifier:Calendar.Identifier.gregorian)
        let comps = (cal as NSCalendar).components([.hour, .minute, .second, .nanosecond], from:self)
        var hour = comps.hour
        let minute = comps.minute
        let second = comps.second
        let nano = comps.nanosecond
        var am = false
        if useAm {
            am = ZTime.IsAm(&hour!)
        }
        return (hour!, minute!, second!, nano!,am)
    }

    fileprivate func getDateComponent(_ time:ZTime, timezone:ZTimeZone?) -> (DateComponents, Calendar) {
        var cal = Calendar(identifier:Calendar.Identifier.gregorian)
        cal.firstWeekday = 2
        let comps = (cal as NSCalendar).components([.day, .month, .year], from:time) // , .weekday
        (comps as NSDateComponents).timeZone = timezone as TimeZone?
        return (comps, cal)
    }
    
    func GetGregorianDateParts(timezone:ZTimeZone? = nil) -> (Int,Month,Int,Weekday) { // returns year, month, day, weekday
        let (comps, _) = getDateComponent(self, timezone:timezone)
        let day = comps.day
        let month = comps.month
        let year = comps.year
        var weekday = Weekday.none
        if let w = comps.weekday {
            weekday = Weekday(rawValue:w) ?? .none
        }
        return (year!, Month(rawValue:month!)!, day!, weekday)
    }

    func GetGregorianDateDifferenceParts(_ toTime:ZTime, timezone:ZTimeZone? = nil) -> (Int,Month,Int,Weekday) { // returns year, month, day, weekday
        let (myComps, cal) = getDateComponent(self, timezone:timezone)
        let (toComps, _) = getDateComponent(toTime, timezone:timezone)
        let unit = NSCalendar.Unit(rawValue:NSCalendar.Unit.day.rawValue | NSCalendar.Unit.month.rawValue | NSCalendar.Unit.year.rawValue)
        let comps = (cal as NSCalendar).components(unit, from:myComps, to:toComps) // options:NSCalendar.Options()
        let day = comps.day
        let month = comps.month
        let year = comps.year
        var weekday = Weekday.none
        if let w = comps.weekday {
            weekday = Weekday(rawValue:w) ?? .none
        }
        return (year!, Month(rawValue:month!)!, day!, weekday)
    }

    func GetGregorianTimeDifferenceParts(_ toTime:ZTime, timezone:ZTimeZone? = nil) -> (Int, Int,Int,Int) { // returns day, hour, minute, secs
        let (myComps, cal) = getDateComponent(self, timezone:timezone)
        let (toComps, _) = getDateComponent(toTime, timezone:timezone)
        let unit = NSCalendar.Unit(rawValue:NSCalendar.Unit.day.rawValue | NSCalendar.Unit.hour.rawValue | NSCalendar.Unit.minute.rawValue | NSCalendar.Unit.second.rawValue)
        let comps = (cal as NSCalendar).components(unit, from:myComps, to:toComps, options:NSCalendar.Options())
        let day = comps.day
        let hour = comps.hour
        let minute = comps.minute
        let second = comps.second
        return (day!, hour!, minute!, second!)
    }

    static func IsAm(_ hour:inout Int) -> (Bool) {
        var am = true
        if hour >= 12 {
            am = false
        }
        hour %= 12
        if hour == 0 {
            hour = 12
        }
        return am
    }
    
    static func Get24Hour(_ hour:Int, am:Bool) -> Int {
        var h = hour
        if h == 12 {
            h = 0
        }
        if !am {
            h += 12
        }
        h %= 24
        
        return h
    }

    func IsToday() -> Bool {
        return NSCalendar.current.isDateInToday(self)
    }
    
    func GetNiceString(locale:String = ZLocaleEngUsPosix, timezone: ZTimeZone? = nil) -> String {
        if IsToday() {
            return ZLocale.GetToday() + " " + GetString(format:"HH:mm", locale:locale, timezone:timezone)
        }
        return GetString(format:ZTime.NiceFormat, locale:locale, timezone:timezone)
    }

    func GetNiceDaysSince(locale:String = ZLocaleEngUsPosix, timezone: ZTimeZone? = nil) -> String {
        let now = ZTime.Now
        let isPast = (now > self)
        let (day, _, _, _) = GetGregorianTimeDifferenceParts(now, timezone:timezone)
        var preposition = ZTS("ago") // generic word for 5 days ago
        if !isPast {
            preposition = ZTS("until") // generic word for 5 days until
        }
        switch day {
        case 0:
            return ZLocale.GetToday()
        case 1:
            return isPast ? ZLocale.GetYesterday() : ZLocale.GetTomorrow()
        case 2, 3, 4, 5, 6, 7:
            return "\(day) " + ZLocale.GetDay(plural:true) + " " + preposition
        default:
            return GetString(format:"MMM dd", locale:locale, timezone:timezone)
        }
    }
    
    func GetString(format:String = ZTime.IsoFormat, locale:String = ZLocaleEngUsPosix, timezone: ZTimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        if timezone != nil {
            formatter.timeZone = timezone as TimeZone!
        }
        if locale == "" {
            formatter.locale = Locale.current
        } else {
            formatter.locale = Locale(identifier:locale)
        }
        return formatter.string(from: self)
    }
    
    func GetIsoString(format:String = ZTime.IsoFormat, useNull:Bool = false) -> String {
        if useNull && IsNull {
            return "null"
        }
        return GetString(format:format, timezone:ZTimeZone(identifier:"UTC"))
    }
    
    static func GetDurationSecsAsHMSString(_ dur:Double) -> String {
        var str = ""
        let h = Int(dur) / 3600
        var m = Int(dur) / 60
        if h > 0 {
            m %= 60
            str = "\(h):"
        }
        let s = Int(dur) % 60
        str += String(format:"%02d:%02d", m, s)
        
        return str
    }
}

extension ZTime {
    static func UpdateIfOlderThanSecs(_ secs:Double, time:inout ZTime) -> Bool {
        if time < ZTime.Now - secs {
            time = ZTime.Now
            return true
        }
        return false
    }
}

