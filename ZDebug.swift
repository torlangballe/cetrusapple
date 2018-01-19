//
//  ZDebug.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

struct ZDebug {
    static let mutex = ZMutex()
    static var storePrintLines = 0
    static var storedLines = [String]()
    static var lastStampTime = ZTime.Null
    static func Print(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
        var str = ""
        if ZTime.UpdateIfOlderThanSecs(3, time:&lastStampTime) {
            str = lastStampTime.GetString(format:"============= yy-MM-dd' 'HH:mm:ssZZ =============\n")
        }
        for (i, item) in items.enumerated() {
            if i != 0 {
                str += separator
            }
            str += String(describing: item ?? "<nil>")
        }
        mutex.Lock()
        if ZDebug.storePrintLines != 0 {
            if ZDebug.storedLines.count > ZDebug.storePrintLines {
                ZDebug.storedLines.removeFirst()
            }
            ZDebug.storedLines.append(str)
        }
        mutex.Unlock()
        print(str, terminator:terminator)
    }
/*
    static func ErrorOnRelease() {
        if !_isDebugAssertConfiguration() {
            for i in 1...1000 {
                Print("Should not run on ")
            }
        }
    }
 */
}

