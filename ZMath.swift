//
//  ZMath.swift
//  Created by Tor Langballe on /23/9/14.
//

// #package com.github.torlangballe.zetrus

/* #kotlin-raw:
 import kotlin.math.*
 import java.util.Random
*/

import Foundation
import Darwin

struct ZMath {
    // #swift-only:
    static let PI = Double.pi
    /* #kotlin-raw:
    val PI = kotlin.math.PI
    */
    static let DegreesToMeters = (111.32*1000)
    static let MetersToDegrees = 1 / DegreesToMeters
    static func RadToDeg(_ rad:Double) -> Double     { return rad * 180 / PI }
    static func DegToRad(_ deg:Double) -> Double     { return deg * PI / 180 }
    static func AngleDegToPos(_ deg:Double) -> ZPos  { return ZPos(sin(DegToRad(deg)), -cos(DegToRad(deg))) }
    static func PosToAngleDeg(_ pos:ZPos) -> Double  { return RadToDeg(ArcTanXYToRad(pos)) }
    
    static func GetDistanceFromLongLatInMeters(_ pos1:ZPos, pos2:ZPos) -> Double {
        let R = 6371.0 // Radius of the earth in km
        let dLat = DegToRad(pos2.y - pos1.y)
        let dLon = DegToRad(pos2.x - pos1.x)
        let a = (Pow(sin(dLat / 2), 2) + cos(DegToRad(pos1.y))) * cos(DegToRad(pos2.y)) * Pow(sin(dLon / 2), 2)
        let c = 2 * Double(asin(sqrt(abs(a))))
        return c * R * 1000
    }
    
    static func Pow(_ a:Double, _ power:Double) -> Double {
        // #swift-only:
        return pow(a, power)
        /* #kotlin-raw:
        a.pow(power)
        */
    }
    
    static func ArcTanXYToRad(_ pos:ZPos) -> Double {
        var a = Double(atan2(pos.y, pos.x))
        if a < 0 {
            a += PI * 2
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

    static func NanCheck(_ d:Double, set:Double = -1.0) -> Double {
        // #swift-only:
        if d.isNaN {
            return set
        }
        /* #kotlin-raw:
         if (d.isNaN()) {
            return set
         }
        */
        return d
    }

    // #swift-only:
    static func Random1() -> Double     { return Double(arc4random_uniform(10000)) / Double(10000) }
    static func RandomN(_ n:Int) -> Int { return Int(arc4random_uniform(UInt32(n))) }
    /* #kotlin-raw:
     fun Random1() : Double {
        val random = Random()
        return random.nextDouble()
     }
     fun RandomN(n:Int) : Int {
        val random = Random()
        return random.nextInt(n)
     }
a     */
}

// #swift-only:
func sign<T: FloatingPoint>(_ a:T) -> Int {
    return (a > 0) ? 1 : (a < 0) ? -1 : 0
}
@discardableResult func minimize<T: SignedNumeric & Comparable>(_ me: inout T, _ a: T) -> Bool {
    if a < me {
        me = a
        return true
    }
    return false
}

@discardableResult func maximize<T: SignedNumeric & Comparable>(_ me: inout T, _ a: T) -> Bool {
    if a > me {
        me = a
        return true
    }
    return false
}
/* #kotlin-raw:
fun minimize<T: Comparable>(_ me: inout T, _ a: T) -> Bool {
    if a < me {
        me = a
        return true
    }
    return false
}

@discardableResult func maximize<T: SignedNumeric & Comparable>(_ me: inout T, _ a: T) -> Bool {
    if a > me {
        me = a
        return true
    }
    return false
}
*/

