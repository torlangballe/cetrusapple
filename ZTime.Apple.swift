//
//  ZTimeApple.swift
//
//  Created by Tor Langballe on /31/10/15.
//

// http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns

import Foundation

typealias ZCalendarUnit = NSCalendar.Unit

let ZTimeNull = ZTime(date:Date.distantPast)
let ZTimeDistantFuture = ZTime(date:Date.distantFuture)

class ZTime {
    let date:Date

    static func Now() -> ZTime {
        return ZTime(timeIntervalSinceNow:0)
    }

    var IsNull:Bool {
        return date.timeIntervalSinceReferenceDate == ZTimeNull.date.timeIntervalSinceReferenceDate
    }
    
    var SecsSinceEpoc: Double {
        get { return date.timeIntervalSinceReferenceDate }
    }
    
    init() {
        date = Date.distantPast
    }
    
    init(ztime:ZTime) {
        date = Date(timeIntervalSinceReferenceDate:ztime.date.timeIntervalSinceReferenceDate)
    }
    
    init(timeIntervalSinceNow:TimeInterval) {
        date = Date(timeIntervalSinceNow:timeIntervalSinceNow)
    }

    init(date:Date) {
        self.date = date
    }
    
    init(year:Int, month:ZMonth = .none, day:Int = -1, hour:Int = 0, minute:Int = 0, second:Int = 0, nano:Int = 0, timezone:ZTimeZone? = nil) {
        let cal = Calendar(identifier:Calendar.Identifier.gregorian)
        var comps = DateComponents()
        
        let t = ZTime.Now()
        let parts = t.GetGregorianDateParts(timezone:timezone)
        
        comps.year = (year == -1 ? parts.year : year)
        comps.month = month == .none ? parts.month.rawValue : month.rawValue
        comps.day = day == -1 ? parts.day : day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        comps.nanosecond = nano
        (comps as NSDateComponents).timeZone = timezone as TimeZone?
        let d = cal.date(from: comps)
        date = Date(timeIntervalSinceReferenceDate:d!.timeIntervalSinceReferenceDate)
    }
    
    convenience init?(iso8601Z:String) {
        var format = ZTimeIsoFormat
        if iso8601Z.contains(".") {
            format = ZTimeIsoFormatWithMSecs
        }
        let zone = ZTimeZone(identifier:"UTC")
        self.init(format:format, dateString:iso8601Z, locale:ZLocaleEngUsPosix, timezone:zone)
    }
    
    convenience init?(format:String, dateString:String, locale:String = "", timezone:ZTimeZone? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        if locale == "" {
            formatter.locale = Locale.current
        } else {
            formatter.locale = Locale(identifier:locale)
        }
        if timezone != nil {
            formatter.timeZone = timezone as TimeZone?
        }
        if let date = formatter.date(from: dateString) {
            self.init(timeIntervalSinceNow:date.timeIntervalSinceReferenceDate)
        } else {
            self.init(ztime:ZTimeNull)
        }
    }
    
    func GetGregorianTimeParts(useAm:Bool = false, timezone:ZTimeZone? = nil) -> (Int,Int,Int,Int,Bool) { // hour, min, sec, nano, isam
        let cal = Calendar(identifier:Calendar.Identifier.gregorian)
        let comps = (cal as NSCalendar).components([.hour, .minute, .second, .nanosecond], from:self.date)
        (comps as NSDateComponents).timeZone = timezone as TimeZone?
        var hour = comps.hour!
        let minute = comps.minute!
        let second = comps.second!
        let nano = comps.nanosecond!
        var am = false
        if useAm {
            (am, hour) = ZTime.IsAm(hour:hour)
        }
        return (hour, minute, second, nano, am)
    }

    fileprivate func getDateComponent(_ time:ZTime, timezone:ZTimeZone?) -> (DateComponents, Calendar) {
        var cal = Calendar(identifier:Calendar.Identifier.gregorian)
        cal.firstWeekday = 2
        let comps = (cal as NSCalendar).components([.day, .month, .year], from:time.date) // , .weekday
        (comps as NSDateComponents).timeZone = timezone as TimeZone?
        return (comps, cal)
    }
    
    func GetGregorianDateParts(timezone:ZTimeZone? = nil) -> ZGregorianParts {
        var g = ZGregorianParts()
        let (comps, _) = getDateComponent(self, timezone:timezone)
        g.day = comps.day!
        let m = comps.month
        g.year = comps.year!
        if let w = comps.weekday {
            g.weekday = ZWeekday(rawValue:w) ?? .none
        }
        g.month = ZMonth(rawValue:m!)!
        return g
    }

    func GetGregorianDateDifferenceParts(_ toTime:ZTime, timezone:ZTimeZone? = nil) -> ZGregorianParts {
        var g = ZGregorianParts()
        let (myComps, cal) = getDateComponent(self, timezone:timezone)
        let (toComps, _) = getDateComponent(toTime, timezone:timezone)
        let unit = NSCalendar.Unit(rawValue:NSCalendar.Unit.day.rawValue | NSCalendar.Unit.month.rawValue | NSCalendar.Unit.year.rawValue)
        let comps = (cal as NSCalendar).components(unit, from:myComps, to:toComps) // options:NSCalendar.Options()
        g.day = comps.day!
        let m = comps.month
        g.year = comps.year!
        if let w = comps.weekday {
            g.weekday = ZWeekday(rawValue:w) ?? .none
        }
        g.month = ZMonth(rawValue:m!)!
        return g
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

    func IsToday() -> Bool {
        return NSCalendar.current.isDateInToday(self.date)
    }
    
    func GetString(format:String = ZTimeIsoFormat, locale:String = ZLocaleEngUsPosix, timezone: ZTimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        if timezone != nil {
            formatter.timeZone = timezone as TimeZone?
        }
        if locale == "" {
            formatter.locale = Locale.current
        } else {
            formatter.locale = Locale(identifier:locale)
        }
        return formatter.string(from: self.date)
    }
}

func +(me: ZTime, add:Double) -> ZTime {
    return ZTime(timeIntervalSinceNow:me.date.timeIntervalSinceNow + add)
}

func -(me: ZTime, sub:Double) -> ZTime {
    return ZTime(timeIntervalSinceNow:me.date.timeIntervalSinceNow - sub)
}

func -(me: ZTime, sub:ZTime) -> Double {
    return me.date.timeIntervalSinceReferenceDate - sub.date.timeIntervalSinceReferenceDate    
}

func <(me: ZTime, sub:ZTime) -> Bool {
    return me.date.timeIntervalSinceReferenceDate < sub.date.timeIntervalSinceReferenceDate
}

func >(me: ZTime, sub:ZTime) -> Bool {
    return me.date.timeIntervalSinceReferenceDate > sub.date.timeIntervalSinceReferenceDate
}

