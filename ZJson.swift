//
//  ZJson.swift
//  SwiftyJSON
//
//  Created by Tor Langballe on /1/11/15.
//
//

import Foundation

// http://www.atimi.com/simple-json-parsing-swift-2/

// https://mikeash.com/pyblog/friday-qa-2017-07-14-swiftcodable.html

// http://davelyon.net/2017/08/16/jsondecoder-in-the-real-world?utm_campaign=This%2BWeek%2Bin%2BSwift&utm_medium=email&utm_source=This_Week_in_Swift_145


typealias ZJSON = JSON

extension ZJSON {
    static func FromString(_ rawUtf8String:String) ->ZJSON? {
        if let data = ZData(utfString:rawUtf8String) {
            return ZJSON(data:data)
        }
        return nil
    }
    
    init(time:ZTime) {
        let str = time.GetIsoString()
        self.init(str)
    }
    
    static func JDict() -> ZJSON {
        return ZJSON([String:JSON]())
    }
    
    static func Null() -> ZJSON {
        return ZJSON(NSNull.self)
    }
    
    var data:ZData? {
        get {
            do {
                let data = try self.rawData()
                return data
            } catch {
                return nil
            }            
        }
    }
    
    var optionalValue: AnyObject? {
        if rawValue is NSNull {
            return nil
        }
        return rawValue as AnyObject?
    }
    
    var stringStringDictionaryValue: [String:String] {
        get {
            var dict = [String:String]()
            if let dj = self.dictionary {
                for (k, v) in dj {
                    if let s = v.string {
                        dict[k] = s
                    }
                }
            }
            return dict
        }
    }
    
    var dictionaryObjectValue: [String:AnyObject] {
        return dictionaryObject as [String : AnyObject]? ?? [:]
    }
    
    var stringArrayValue: [String] {
        get {
            var strings = [String]()
            if let array = self.array {
                for a in array {
                    if let s = a.string {
                        strings.append(s)
                    }
                }
            }
            return strings
        }
    }
    var intArrayValue: [Int] {
        get {
            var ints = [Int]()
            if let array = self.array {
                for a in array {
                    if let s = a.int {
                        ints.append(s)
                    }
                }
            }
            return ints
        }
    }
    var isoTime: ZTime? {
        get {
            if let str = self.string {
                var t = ZTime(iso8601Z:str)
                if t == nil {
                    t = ZTime(format:ZTime.IsoFormatWithZone, dateString:str)
                }
                return t
            }
            return nil
        }
    }

    var isoTimeValue: ZTime {
        get {
            if let t = isoTime {
                return t
            }
            return ZTime()
        }
    }
}

