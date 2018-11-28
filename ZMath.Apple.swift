//
//  ZMath.swift
//  Created by Tor Langballe on /23/9/14.
//

import Foundation
import Darwin

extension ZMath {
    static func Pow(_ a:Double, _ power:Double) -> Double {
        return pow(a, power)
    }
    

    static func NanCheck(_ d:Double, set:Double = -1.0) -> Double {
        if d.isNaN {
            return set
        }
        return d
    }
    
    static func Random1() -> Double     { return Double(arc4random_uniform(10000)) / Double(10000) }
    static func RandomN(_ n:Int) -> Int { return Int(arc4random_uniform(UInt32(n))) }
}

func sign<T: FloatingPoint>(_ a:T) -> Int {
    return (a > 0) ? 1 : (a < 0) ? -1 : 0
}

