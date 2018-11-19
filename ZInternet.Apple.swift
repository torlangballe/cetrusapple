//
//  ZInternet.Apple.swift
//
//  Created by Tor Langballe on 11/15/18.
//

import Foundation

class ZIPAddress {
}

struct ZInternet {
    func ResolveAddress(address:String, got:(_ a:ZIPAddress )->Void) {
        let ip = ZIPAddress()
        // TODO: do this
        got(ip)
    }

    func SendWithUDP(address:ZIPAddress, port:Int, data:ZData, done:(_ e:ZError?)->Unit) {
        // TODO: do this
    }
}

class ZRateLimiter {
    let max:Int
    let durationSecs:Double
    
    var timeStamps = [ZTime]()
    init(max:Int, durationSecs:Double) {
        self.max = max
        self.durationSecs = durationSecs
    }
    
    func Add() {
        timeStamps.append(ZTime.Now())
    }
    
    func IsExceded() -> Bool {
        timeStamps.removeIf { $0.Since() > durationSecs  }
        return timeStamps.count >= max
    }
}

