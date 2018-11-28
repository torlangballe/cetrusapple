//
//  ZDebug.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

class ZDebug {
    static let mutex = ZMutex()
    static var storePrintLines = 0
    static var storedLines = [String]()
    static var lastStampTime = ZTimeNull
    static var printHooks = [(String)->()]()
    
    static func basePrint(_ str: String, separator: String = " ", terminator: String = "\n") {
        print(str, separator:separator, terminator:terminator)
    }
    
    static func IsRelease() -> Bool {
        return !_isDebugAssertConfiguration()
    }
    
    static func IsMinIOS11() -> Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }
}

