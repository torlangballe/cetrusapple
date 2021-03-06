//
//  ZWords.swift
//  capsule.fm
//
//  Created by Tor Langballe on /11/8/18.
//  Copyright © 2018 Capsule.fm. All rights reserved.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation

struct ZWords {
    static func Pluralize(word:String, count:Double, langCode:String? = nil, pluralWord:String? = nil) -> String {
        var lang = ZLocale.GetDeviceLanguageCode()
        if langCode != nil {
            lang = langCode!
        }
        if pluralWord != nil {
            if count == 1.0 {
                return word
            }
            return pluralWord!
        }
        if lang == "no" {
            return (count == 1.0) ? word : word + "er"
        }
        if lang == "d" {
            return (count == 1.0) ? word : word + "e"
        }
        if lang == "ja" {
            return word
        }
        // english
        if count == 1.0 {
            return word
        }
        if ZStr.Tail(word) == "s" {
            return word + "es"
        }
        return word + "s"
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
    
    static func GetYesterday() -> String {
        return ZTS("Yesterday") // generic name for yesterday
    }
    
    static func GetTomorrow() -> String {
        return ZTS("Tomorrow") // generic name for tomorrow
    }
    
    
    // these three functions insert day/month/year symbol after date in picker, only needed for ja so far.
    static func GetDateInsertDaySymbol() -> String {
        if ZLocale.GetDeviceLanguageCode() == "ja" {
            return "日"
        }
        return ""
    }
    
    static func GetDateInsertMonthSymbol() -> String {
        if ZLocale.GetDeviceLanguageCode() == "ja" {
            return "月"
        }
        return ""
    }
    
    static func GetDateInsertYearSymbol() -> String {
        if ZLocale.GetDeviceLanguageCode() == "ja" {
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
    
    static func GetDay(plural:Bool = false) -> String {
        if plural {
            return ZTS("Days") // generic name for the plural of a number of days since/until etc
        }
        return ZTS("Day") // generic name for a days since/until etc
    }
    
    
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
            str = ZStr.Head(str, chars:chars)
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
        let Meter = 1
        let Km = 2
        let Mile = 3
        let Yard = 4
        
        var type = Meter
        var d = meters
        var distance = ""
        var word = ""
        
        if metric {
            if d >= 1000 {
                type = Km
                d /= 1000
            }
        } else {
            d /= 1.0936133
            if d >= 1760 {
                type = Mile
                d /= 1760
                distance = ZStr.Format("%.1lf", d)
            } else {
                type = Yard
                d = ZMath.Floor(d)
                distance = "\(d)"
            }
        }
        switch(type) {
        case Meter:
            word = GetMeter(plural:true)
            
        case Km:
            word = GetKiloMeter(plural:true)
            
        case Mile:
            word = GetMile(plural:true)
            
        case Yard:
            word = GetYard(plural:true)

        default:
            break
        }
        if type == Meter || type == Yard && round {
            d = ZMath.Ceil(((ZMath.Ceil(d) + 9) / 10) * 10)
            distance = ("\(Int(d))")
        } else if round && d > 50 {
            distance = ZStr.Format("%d", Int(d))
        } else {
            distance = ZStr.Format("%.1lf", d)
        }
        return distance + " " + word
    }
    
    static func MemorySizeAsString(_ b:Int64, langCode:String = "", maxSignificant:Int = 3, isBits:Bool = false) -> String {
        let kiloByte  = 1024.0
        let megaByte  = kiloByte * 1024
        let gigaByte  = megaByte * 1024
        let terraByte = gigaByte * 1024
        var word = "T"
        var n = Double(b) / terraByte
        let d = Double(b)
        if d < kiloByte {
            word = ""
            n = Double(b)
        } else if d < megaByte {
            word = "K"
            n = Double(b)/kiloByte
        } else if d < gigaByte {
            word = "M"
            n = Double(b)/megaByte
        } else if d < terraByte {
            word = "G"
            n = Double(b)/gigaByte
        }
        word += (isBits ? "b" : "B")

        let str = ZStr.NiceDouble(n, maxSig:maxSignificant) + " " + word
        return str
    }
    
    static func GetHemisphereDirectionsFromGeoAlignment(_ alignment:ZAlignment, separator:String, langCode:String) -> String {
        var str = ""
        if alignment & ZAlignment.Top {
            str = ZTS("North", langCode:langCode) // General name for north as in north-east wind etc
        }
        if alignment & ZAlignment.Bottom {
            str = ZStr.ConcatNonEmpty(sep:separator, items:[str, ZTS("South", langCode:langCode)]) // General name for south as in south-east wind etc
        }
        if alignment & ZAlignment.Left {
            str = ZStr.ConcatNonEmpty(sep:separator, items:[str, ZTS("West", langCode:langCode)]) // General name for west as in north-west wind etc
        }
        if alignment & ZAlignment.Right {
            str = ZStr.ConcatNonEmpty(sep:separator, items:[str, ZTS("East", langCode:langCode)]) // General name for north as in north-east wind etc
        }
        return str
    }
}
