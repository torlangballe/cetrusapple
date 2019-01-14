//
//  ZTime.swift
//  Zed
//
//  Created by Tor Langballe on /31/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation

let ZLocaleEngUsPosix = "en_US_POSIX"

enum ZWeekday:Int { case none = 0, mon, tue, wed, thu, fri, sat, sun }
enum ZMonth:Int   { case none = 0, jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec }

struct ZGregorianParts : ZCopy {
    var year:Int = 0
    var month:ZMonth = ZMonth.none
    var day:Int = 0
    var hour:Int = 0
    var minute:Int = 0
    var second:Int = 0
    var nano:Int = 0
    var weekday:ZWeekday = ZWeekday.none
}

extension ZTime {
    func Since() -> Double {
        return ZTime.Now().SecsSinceEpoc - self.SecsSinceEpoc
    }
    
    func Until() -> Double {
        return self - ZTime.Now()
    }

    static func IsAm(hour:Int) -> (Bool, Int) { // isam, 12-hour hour
        var h = hour
        var am = true
        if hour >= 12 {
            am = false
        }
        h %= 12
        if h == 0 {
            h = 12
        }
        return (am, h)
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

    func GetNiceString(locale:String = ZLocaleEngUsPosix, timezone: ZTimeZone? = nil) -> String {
        if IsToday() {
            return ZWords.GetToday() + " " + GetString(format:"HH:mm", locale:locale, timezone:timezone)
        }
        return GetString(format:ZTimeNiceFormat, locale:locale, timezone:timezone)
    }

    func GetNiceDaysSince(locale:String = ZLocaleEngUsPosix, timezone: ZTimeZone? = nil) -> String {
        let now = ZTime.Now()
        let isPast = (now > self)
        let (day, _, _, _) = GetGregorianTimeDifferenceParts(now, timezone:timezone)
        var preposition = ZTS("ago") // generic word for 5 days ago
        if !isPast {
            preposition = ZTS("until") // generic word for 5 days until
        }
        switch day {
        case 0:
            return ZWords.GetToday()
        case 1:
            return isPast ? ZWords.GetYesterday() : ZWords.GetTomorrow()
        case 2, 3, 4, 5, 6, 7:
            return "\(day) " + ZWords.GetDay(plural:true) + " " + preposition
        default:
            return GetString(format:"MMM dd", locale:locale, timezone:timezone)
        }
    }
    
    func GetIsoString(format:String = ZTimeIsoFormat, useNull:Bool = false) -> String {
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
        str += ZStr.Format("%02d:%02d", m, s)
        
        return str
    }
}

let ZTimeIsoFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" // UploadFileToBucket
let ZTimeIsoFormatWithMSecs = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
let ZTimeIsoFormatCompact = "yyyyMMdd'T'HHmmss'Z'"

let ZTimeIsoFormatWithZone = "yyyy-MM-dd'T'HH:mm:ssZZZZZ" // UploadFileToBucket
let ZTimeIsoFormatWithMSecsWithZone = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
let ZTimeIsoFormatCompactWithZone = "yyyyMMdd'T'HHmmssZZZZZ"

let ZTimeCompactFormat = "yyyy-MM-dd' 'HH:mm:ss"
let ZTimeNiceFormat = "yy-MMM-dd' 'HH:mm"
let ZTimeHTTPHeaderDateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"

let ZTimeMinute = 60.0
let ZTimeHour = 3600.0
let ZTimeDay = 86400.0

class ZDeltaTimeGetter {
    var lastGetTime:ZTime = ZTimeNull
    var lastGetValue:Double? = nil
    
    func Get(get:() -> Double) -> (Double, Double) {
        var v = get()
        var delta = 0.0
        var interval = 0.0
        let t = ZTime.Now()
        if lastGetValue != nil {
            delta = v - lastGetValue!
            interval = t - lastGetTime
        }
        lastGetValue = v
        lastGetTime = ZTime.Now()
    
        return (delta, interval)
    }
}
