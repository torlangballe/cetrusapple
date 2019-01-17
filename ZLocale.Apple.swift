//
//  ZWords.swift
//
//  Created by Tor Langballe on /1/11/15.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation
//import UIKit
import AVFoundation

struct ZLocale {
    static func GetDeviceLanguageCode(forceNo:Bool = true) -> String {
        let code = NSLocale.preferredLanguages.first!
        let (lang, _) = GetLangCodeAndCountryFromLocaleId(code, forceNo:forceNo)
        return lang
    }
    
    static func GetLangCodeAndCountryFromLocaleId(_ bcp:String, forceNo:Bool = true) -> (String, String) { // lang, country-code
        var (lang, ccode) = ZStr.SplitInTwo(bcp, sep:"-")
        if ccode.isEmpty {
            let (_, ccode) = ZStr.SplitInTwo(bcp, sep:"_")
            if ccode.isEmpty {
                let parts = ZStr.Split(bcp, sep:"-")
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
}

