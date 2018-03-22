//
//  ZLocale.swift
//  SwiftyJSON
//
//  Created by Tor Langballe on /1/11/15.
//
//

import Foundation
import UIKit
import AVFoundation

struct ZLocale {
    
    static var UsesMetric: Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem)! as AnyObject).boolValue
    }

    static var UsesCelsius: Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem)! as AnyObject).boolValue
    }

    static var Uses24Hour: Bool {
        let locale = Locale.current
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:locale)!
        return dateFormat.range(of: "a") == nil
    }

    static func GetBCPFromLanguageAndCountryCode(langCode: String, countryCode:String) -> String {
        var ccode = countryCode
        if ccode == "uk" {
            ccode = "gb"
        }
        if ccode == "" {
            switch langCode {
                case "ja":
                    ccode = "jp"
                case "sw":
                    ccode = "se"
                case "da":
                    ccode = "dk"
                case "en":
                    ccode = "gb"
                default:
                    ccode = langCode
            }
            ccode = langCode
        }
        return langCode.lowercased() + "-" + ccode.uppercased()
    }
    
    static func GetDeviceLanguageCode(forceNo:Bool = true) -> String {
        let code = NSLocale.preferredLanguages.first!
        let (lang, _) = GetLangCodeAndCountryFromLocaleId(code, forceNo:forceNo)
        return lang
    }
    
    static func GetLangCodeAndCountryFromLocaleId(_ bcp:String, forceNo:Bool = true) -> (String, String) { // lang, country-code
        var lang = ""
        var ccode = ""
        
        if !ZStrUtil.SplitToArgs(bcp, sep:"-", a:&lang, b:&ccode) {
            if !ZStrUtil.SplitToArgs(bcp, sep:"_", a:&lang, b:&ccode) {
                let parts = ZStrUtil.Split(bcp, sep:"-")
                if parts.count > 2 {
                    return (parts.first!, parts.last!)
                }
                return (bcp, "")
            }
        }
        if lang == "nb" {
            lang = "no"
        }
        return (lang, ccode)
    }
    
    static func Pluralize(word:String, count:Double, langCode:String? = nil, pluralWord:String? = nil) -> String {
        var lang = GetDeviceLanguageCode()
        if langCode != nil {
            lang = langCode!
        }
        if pluralWord != nil {
            if count == 1 {
                return word
            }
            return pluralWord!
        }
        switch lang {
            case "no":
                return (count == 1) ? word : word + "er"
            case "de":
                return (count == 1) ? word : word + "e"
            case "ja":
                return word
            default:
                if count == 1 {
                    return word
                }
                if word.lastCharAsString == "s" {
                    return word + "es"
                }
                return word + "s"
        }
    }
    
    static func GetLogin() -> String {
        return ZTS("Log in") // generic name for login button etc
    }
    
    static func GetLogout() -> String {
        return ZTS("Log out") // generic name for login button etc
    }
    
    static func GetAnd() -> String {
        return ZTS("And") // generic name for and, i.e: cats and dogs
    }

    static func GetHour(plural:Bool = false) -> String {
        if plural {
            return ZTS("hours") // generic name for hours plural
        }
        return ZTS("hour")    // generic name for hour singular
    }
    
    static func GetToday() -> String {
        return ZTS("Today") // generic name for today
    }

    // these three functions insert day/month/year symbol after date in picker, only needed for ja so far.
    static func GetDateInsertDaySymbol() -> String {
        if GetDeviceLanguageCode() == "ja" || ZKeyValueStore.StringForKey(ZTSOverrideKey) == "ja" {
            return "日"
        }
        return ""
    }

    static func GetDateInsertMonthSymbol() -> String {
        if GetDeviceLanguageCode() == "ja" || ZKeyValueStore.StringForKey(ZTSOverrideKey) == "ja" {
            return "月"
        }
        return ""
    }

    static func GetDateInsertYearSymbol() -> String {
        if GetDeviceLanguageCode() == "ja" || ZKeyValueStore.StringForKey(ZTSOverrideKey) == "ja" {
            return "年"
        }
        return ""
    }

    static func GetMinute(plural:Bool = false) -> String {
        if plural {
            return ZTS("minutes")   // generic name for minutes plural
        }
        return ZTS("minute")   // generic name for minute singular
    }
    
    static func GetMeter(plural:Bool = false, langCode:String = "") -> String {
        if plural {
            return ZTS("meters", langCode:langCode)   // generic name for meters plural
        }
        return ZTS("meter", langCode:langCode)   // generic name for meter singular
    }

    static func GetKiloMeter(plural:Bool = false, langCode:String = "") -> String {
        if plural {
            return ZTS("kilometers", langCode:langCode)   // generic name for kilometers plural
        }
        return ZTS("kilometer", langCode:langCode)   // generic name for kilometer singular
    }

    static func GetMile(plural:Bool = false, langCode:String = "") -> String {
        if plural {
            return ZTS("miles", langCode:langCode)   // generic name for miles plural
        }
        return ZTS("mile", langCode:langCode)   // generic name for mile singular
    }

    static func GetYard(plural:Bool = false, langCode:String = "") -> String {
        if plural {
            return ZTS("yards", langCode:langCode)   // generic name for yards plural
        }
        return ZTS("yard", langCode:langCode)   // generic name for yard singular
    }
    
    static func GetInch(plural:Bool = false, langCode:String = "") -> String {
        if plural {
            return ZTS("inches", langCode:langCode)   // generic name for inch plural
        }
        return ZTS("inch", langCode:langCode)   // generic name for inches singular
    }

    static func GetDayPeriod() -> String { return ZTS("am/pm") }        // generic name for am/pm part of day when used as a column title etc
    static func GetOk() -> String { return ZTS("OK") }                  // generic name for OK in button etc
    static func GetSet() -> String { return ZTS("Set") }                // generic name for Set in button, i.e set value
    static func GetOff() -> String { return ZTS("Off") }                // generic name for Off in button, i.e value/switch is off. this is RMEOVED by VO in value
    static func GetOpen() -> String { return ZTS("Open") }              // generic name for button to open a window or something
    static func GetBack() -> String { return ZTS("Back") }              // generic name for back button in navigation bar
    static func GetCancel() -> String { return ZTS("Cancel") }          // generic name for Cancel in button etc
    static func GetClose() -> String { return ZTS("Close") }            // generic name for Close in button etc
    static func GetPlay() -> String { return ZTS("Play") }              // generic name for Play in button etc
    static func GetPost() -> String { return ZTS("Post") }              // generic name for Post in button etc, post a message to social media etc
    static func GetEdit() -> String { return ZTS("Edit") }              // generic name for Edit in button etc, to start an edit action
    static func GetReset() -> String { return ZTS("Reset") }            // generic name for Reset in button etc, to reset/restart something
    static func GetPause() -> String { return ZTS("Pause") }            // generic name for Pause in button etc
    static func GetSave() -> String { return ZTS("Save") }              // generic name for Save in button etc
    static func GetAdd() -> String { return ZTS("Add") }                // generic name for Add in button etc
    static func GetDelete() -> String { return ZTS("Delete") }          // generic name for Delete in button etc
    static func GetExit() -> String { return ZTS("Exit") }              // generic name for Exit in button etc. i.e: You have unsaved changes. [Save] [Exit]
    static func GetRetryQuestion() -> String { return ZTS("Retry?") }   // generic name for Retry? in button etc, must be formulated like a question
    static func GetFahrenheit() -> String { return ZTS("fahrenheit") }  // generic name for fahrenheit, used in buttons etc.
    static func GetCelsius() -> String { return ZTS("celsius") }        // generic name for celsius, used in buttons etc.
    static func GetSettings() -> String { return ZTS("settings") }      // generic name for settings, used in buttons / title etc

    static func GetDayOfMonth() -> String { return ZTS("Day") }   // generic name for the day of a month i.e 23rd of July
    static func GetMonth() -> String { return ZTS("Month") }      // generic name for month.
    static func GetYear() -> String { return ZTS("Year") }        // generic name for year.

    static func GetSelected(_ on:Bool) -> String {
        if on {
            return ZTS("Selected") // generic name for selected in button/title/switch, i.e something is selected/on
        } else {
            return ZTS("unselected") // generic name for unselected in button/title/switch, i.e something is unselected/off
        }
    }

    static func GetMonthFromNumber(_ m:Int, chars:Int = -1) -> String {
        var str = ""
        switch m {
            case 1:
                str = ZTS("January")  // name of month
            case 2:
                str = ZTS("February") // name of month
            case 3:
                str = ZTS("March")    // name of month
            case 4:
                str = ZTS("April")   // name of month
            case 5:
                str = ZTS("May") // name of month
            case 6:
                str = ZTS("June") // name of month
            case 7:
                str = ZTS("July") // name of month
            case 8:
                str = ZTS("August") // name of month
            case 9:
                str = ZTS("September") // name of month
            case 10:
                str = ZTS("October") // name of month
            case 11:
                str = ZTS("November") // name of month
            case 12:
                str = ZTS("December") // name of month
            default:
                break
        }
        if chars != -1 {
            str = ZStrUtil.Head(str, chars:chars)
        }
        return str
    }        // generic name for year.

    static func GetNameOfLanguageCode(_ langCode:String, inLanguage:String = "en") -> String {
        switch langCode.lowercased() {
            case "en":
                return ZTS("English") // name of english language
            case "de":
                return ZTS("German") // name of german language
            case "ja", "jp":
                return ZTS("Japanese") // name of english language
            case "no", "nb", "nn":
                return ZTS("Norwegian") // name of norwegian language
            case "us":
                return ZTS("American") // name of american language/person
            case "ca":
                return ZTS("Canadian") // name of canadian language/person
            case "nz":
                return ZTS("New Zealander") // name of canadian language/person
            case "at":
                return ZTS("Austrian") // name of austrian language/person
            case "ch":
                return ZTS("Swiss") // name of swiss language/person
            case "in":
                return ZTS("Indian") // name of indian language/person
            case "gb", "uk":
                return ZTS("British") // name of british language/person
            case "za":
                return ZTS("South African") // name of south african language/person
            case "ae":
                return ZTS("United Arab Emirati") // name of UAE language/person
            case "id":
                return ZTS("Indonesian") // name of indonesian language/person
            case "sa":
                return ZTS("Saudi Arabian") // name of saudi language/person
            case "au":
                return ZTS("Australian") // name of australian language/person
            case "ph":
                return ZTS("Filipino") // name of filipino language/person
            case "sg":
                return ZTS("Singaporean") // name of singaporean language/person
            case "ie":
                return ZTS("Irish") // name of irish language/person
            default:
                return ""
        }
    }
    

    static func GetDistance(_ meters:Double, metric:Bool, langCode:String, round:Bool) -> String {

        enum Type { case meter, km, mile, yard }

        var type = Type.meter
        var d = meters
        var distance = ""
        var word = ""
        
        if metric {
            if d >= 1000 {
                type = .km
                d /= 1000
            }
        } else {
            d /= 1.0936133
            if d >= 1760 {
                type = .mile
                d /= 1760
                distance = String(format:"%.1lf", d)
            } else {
                type = .yard
                d = floor(d)
                distance = "\(d)"
            }
        }
        switch(type) {
        case .meter:
            word = ZLocale.GetMeter(plural:true)

        case .km:
            word = ZLocale.GetKiloMeter(plural:true)

        case .mile:
            word = ZLocale.GetMile(plural:true)

        case .yard:
            word = ZLocale.GetYard(plural:true)
        }
        if type == .meter || type == .yard && round {
            d = ceil(((ceil(d) + 9) / 10) * 10)
            distance = ("\(Int(d))")
        } else if round && d > 50 {
            distance = String(format:"%d", Int(d))
        } else {
            distance = String(format:"%.1lf", d)
        }
        return distance + " " + word
    }
    
    static func MemorySizeAsString(_ b:Int, langCode:String = "", maxSignificant:Int = 3) -> String {
        let kiloByte  = 1024.0
        let megaByte  = kiloByte * 1024
        let gigaByte  = megaByte * 1024
        let terraByte = gigaByte * 1024

        var word = "TB"
        var n = Double(b) / terraByte
        let d = Double(b)
        switch d {
        case 0..<kiloByte:
            word = "B"
            n = Double(b)
        case kiloByte ..< megaByte:
            word = "KB"
            n = Double(b)/kiloByte
        case megaByte ..< gigaByte:
            word = "MB"
            n = Double(b)/megaByte
        case gigaByte ..< terraByte:
            word = "GB"
            n = Double(b)/gigaByte
        default:
            break
        }
        let str = ZStrUtil.NiceDouble(n, maxSig:maxSignificant) + " " + word
        return str
    }

    static func GetHemisphereDirectionsFromGeoAlignment(_ alignment:ZAlignment, separator:String, langCode:String) -> String {
        var str = ""
        if alignment & .Top {
            str = ZTS("North", langCode:langCode) // General name for north as in north-east wind etc
        }
        if alignment & .Bottom {
            str = ZStrUtil.ConcatNonEmpty(separator:separator, items:str, ZTS("South", langCode:langCode)) // General name for south as in south-east wind etc
        }
        if alignment & .Left {
            str = ZStrUtil.ConcatNonEmpty(separator:separator, items:str, ZTS("West", langCode:langCode)) // General name for west as in north-west wind etc
        }
        if alignment & .Right {
            str = ZStrUtil.ConcatNonEmpty(separator:separator, items:str, ZTS("East", langCode:langCode)) // General name for north as in north-east wind etc
        }
        return str
    }
    
    static func GetCurrentOSLangNameFromMap(map: [String:String]) -> String {
        if let n = map[GetDeviceLanguageCode()] {
            return n
        }
        if let n = map["en"] {
            return n
        }
        return ""
    }
}


