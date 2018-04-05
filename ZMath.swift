//
//  zmath.swift
//  Cetrus
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

import Foundation
import Darwin

let π = Double.pi

struct ZMath {
    static let DegreesToMeters = (111.32*1000)
    static let MetersToDegrees = 1 / DegreesToMeters
    static func RadToDeg(_ rad:Double) -> Double     { return rad * 180 / π }
    static func DegToRad(_ deg:Double) -> Double     { return deg * π / 180 }
    static func AngleDegToPos(_ deg:Double) -> ZPos  { return ZPos(sin(DegToRad(deg)), -cos(DegToRad(deg))) }
    static func PosToAngleDeg(_ pos:ZPos) -> Double  { return RadToDeg(ArcTanXYToRad(pos)) }
    
//    static func Sign(_ a: Double) -> Int {
//        if a > 0.0 {
//            return 1
//        }
//        if a < 0.0 {
//            return -1
//        }
//        return 0
//    }

    static func GetDistanceFromLongLatInMeters(_ pos1:ZPos, pos2:ZPos) -> Double {
        let R = 6371.0 // Radius of the earth in km
        let dLat = DegToRad(pos2.y - pos1.y)
        let dLon = DegToRad(pos2.x - pos1.x)
        let a = (pow(sin(dLat / 2), 2) + cos(DegToRad(pos1.y))) * cos(DegToRad(pos2.y)) * pow(sin(dLon / 2), 2)
        let c = 2 * Double(asin(sqrt(abs(a))))
        return c * R * 1000
    }
    
    static func ArcTanXYToRad(_ pos:ZPos) -> Double {
        var a = Double(atan2(pos.y, pos.x))
        if a < 0 {
            a += π * 2
        }
        return a
    }
    
    static func MixedArrayValueAtIndex(_ array:[Double], index:Double) -> Double {
        if index < 0.0 {
            return array[0]
        }
        if index >= Double(array.count) - 1 {
            return array.last!
        }
        let n = index
        let f = (index - n);
        var v = array[Int(n)] * (1 - f)
        if Int(n) < array.count {
            v += array[Int(n + 1)] * f
            return v
        }
        return array.last ?? 0.0
    }
    
    static func MixedArrayValueAtT(_ array:[Double], t:Double) -> Double {
        return MixedArrayValueAtIndex(array, index:(Double(array.count) - 1) * t)
    }
}

// ios:
extension ZMath {
    static func Random1() -> Double   { return Double(arc4random_uniform(10000)) / Double(10000) }
    static func RandomN(_ n:Int) -> Int { return Int(arc4random_uniform(UInt32(n))) }

    static func NanCheck(_ d:Double, set:Double = -1) -> Double {
        if d.isNaN {
            return set
        }
        return d
    }
}

