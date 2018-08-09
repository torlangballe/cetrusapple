//
//  ZDebug.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

class ZDebug {
    static func basePrint(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
        print(items, separator:separator, terminator:terminator)
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

