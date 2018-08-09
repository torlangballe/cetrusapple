//
//  ZTimeZone.swift
//  Zed
//
//  Created by Tor Langballe on /3/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZTimeZone = TimeZone

extension ZTimeZone {
    
    static var UTC: ZTimeZone {
        return ZTimeZone(identifier:"UTC")!
    }

    static var GTM: ZTimeZone {
        return ZTimeZone(identifier:"GMT")!
    }

    static var DeviceZone: ZTimeZone {
        return TimeZone.autoupdatingCurrent
        //        snew = oldZones->GetValue(szone);
        //        if(snew.Size())
        //        return XTimeZone::FromName(snew);
    }
    
    var NiceName: String {
        var last = ZStr.TailUntil(identifier, sep:"/")
        last = last.replacingOccurrences(of: "_", with:"")
        return last
    }

    var HoursFromUTC: Double {
        return Double(secondsFromGMT()) / 3600
    }
    
    func CalculateOffsetHours(_ time:ZTime = ZTimeNow, localDeltaHours:inout Double) -> Double {
        let secs = secondsFromGMT(for: time.date)
        let lsecs = TimeZone.autoupdatingCurrent.secondsFromGMT(for: time.date)
        localDeltaHours = Double(secs - lsecs) / 3600
        return Double(secs) / 3600
    }
    
    func IsUTC() -> Bool {
        return self == ZTimeZone.UTC
    }
}
