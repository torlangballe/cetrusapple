//
//  ZMath.swift
//  Created by Tor Langballe on /23/9/14.
//

// #package com.github.torlangballe.cetrusandroid

/* #kotlin-raw:
 import kotlin.math.*
 import java.util.Random
*/

import Foundation
import Darwin

struct ZMath {
    static let PI:Double = 3.141592653589793
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
        let a = (Pow(sin(dLat / 2.0), 2.0) + cos(DegToRad(pos1.y))) * cos(DegToRad(pos2.y)) * Pow(sin(dLon / 2.0), 2.0)
        let c = 2.0 * Double(asin(sqrt(abs(a))))
        return c * R * 1000.0
    }

    static func Fraction(_ v:Double) -> Double {
        return v - Floor(v)
    }
    

    static func Floor(_ v:Double) -> Double {
        return floor(v)
    }
    
    static func Ceil(_ v:Double) -> Double {
        return ceil(v)
    }
    
    static func Log10(d:Double) -> Double {
        return log10(d)
    }

    static func GetNiceIncsOf(_ d:Double, incCount:Int, isMemory:Bool)  -> Double {
        let l = floor(log10(d))
        var n = Pow(10.0, l)
        if isMemory {
            n = Pow(1024.0, ceil(l / 3.0))
            while d / n > Double(incCount) {
                n = n * 2.0
            }
        }
        while d / n < Double(incCount) {
            n = n / 2.0
        }
        return n
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
}

