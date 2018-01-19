//
//  ZRegEx.swift
//  Zed
//
//  Created by Tor Langballe on /4/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZRegExOptions = NSRegularExpression.Options
typealias ZMatchingOptions = NSRegularExpression.MatchingOptions

class ZRegEx: NSRegularExpression {
    convenience init(expression:String, options:ZRegExOptions = ZRegExOptions()) {
        try! self.init(pattern:expression, options:options)
    }

    func ItterateStr(_ str:String, options:ZMatchingOptions = ZMatchingOptions(rawValue:0), got:@escaping (_ range:ZRange, _ groupRange:ZRange, _ groupNo:Int, _ match:Int)->Bool) {
        var match = 0
        enumerateMatches(in: str, options:options, range:str.fullNSRange) { (result, flags, stop) in
            let count = result?.numberOfRanges ?? 0
            var s = 1
            if count == 1 {
                s = 0;
            }
            for i in s ..< count {
                let r = result!.range(at: i)
                if r.length > 0 {
                    if !got(result!.range, r, i, match) {
                        stop.pointee = true
                    }
                }
                match += 1
            }
        }
    }

    func ReplacedStr(_ str:String, options:ZMatchingOptions = ZMatchingOptions(), got:@escaping (_ strAdd:inout String, _ matchStr:String, _ groupStr:String)->Bool) -> String {
        var last = 0
        var sadd = ""
        ItterateStr(str, options:options) { (range, groupRange, groupNo, match) in
            var matchStr = ""
            var groupStr = ""
            if range.location > last {
                let prefixRange = NSMakeRange(last, range.location - last)
                let nsprefix = (str as NSString).substring(with:prefixRange)
                sadd = (nsprefix as String)
            }
            matchStr = (str as NSString).substring(with:range)
            groupStr = (str as NSString).substring(with:groupRange)
            let cont = got(&sadd, matchStr, groupStr)
            last = range.End
            return cont
        }
        if last < str.count {
            let suffix = (str as NSString).substring(from: last)
            sadd += suffix
        }
        return sadd;
    }
}
