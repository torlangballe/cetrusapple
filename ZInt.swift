//
//  ZInt.swift
//  PocketProbe
//
//  Created by Tor Langballe on /6/2/18.
//

import Foundation

class ZInt {
    class func BytesToInt<T:BinaryInteger>(_ bytes:[UInt8], out:inout T) {
        var i = 0
        out = 0
        while i < MemoryLayout<T>.size {
            out <<= 8
            out |= T(bytes[i])
            i += 1
        }
    }
}
