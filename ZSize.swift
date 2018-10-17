//
//  ZSize.swift
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

struct ZSize : ZCopy {
    var w:Double = 0.0
    var h:Double = 0.0

    init()                           { self.init(0, 0) }
    init(_ aw:Int, _ ah:Int)         { self.init(Double(aw), Double(ah)) }
    init(_ aw:Float, _ ah:Float)     { self.init(Double(aw), Double(ah)) }

    func GetPos() -> ZPos            { return ZPos(w, h) }
    func IsNull() -> Bool            { return w == 0.0 && h == 0.0 }
    
    // #swift-only:
    init(_ aw:Double, _ ah:Double)   { w = aw; h = ah }
    subscript(vertical:Bool) -> Double {
        get { return vertical ? h : w }
        set { if vertical { h = newValue } else { w = newValue } }
    }
    /* #kotlin-raw:
     operator fun get(vertical: Boolean) : Double {
        if (vertical) { return h }
        return w
     }
     operator fun set(vertical:Boolean, v:Double) {
        if (vertical) { h = v }
        else { w = v }
     }
    */
    
    func Max() -> Double {
        return max(w, h)
    }

    func Min() -> Double {
        return min(w, h)
    }

    func EqualSided() -> ZSize {
        let m = max(w, h)
        return ZSize(m, m)
    }
    func Area() -> Double {
        return w * h
    }
    func compareTo(s:ZSize) -> Int {
        return Int((Area() - s.Area() * 1000)) // will loose presision so half-ass * 1000 hack
    }
    mutating func Maximize(_ a:ZSize) {
        w = max(w, a.w)
        h = max(h, a.h)
    }
/*
    mutating func operator_plusAssign(_ a:ZSize) {
        w += a.w
        h += a.h
    }
    mutating func operator_minusAssign(_ a:ZSize) {
        w -= a.w
        h -= a.h
    }
 */
    mutating func operator_timesAssign(_ a:Double) {
        w *= a
        h *= a
    }
    mutating func operator_timesAssign(_ a:Float) {
        w *= Double(a)
        h *= Double(a)
    }
    func operator_unaryMinus() -> ZSize {
        return ZSize(-w, -h)
    }
    func equals(_ a:ZSize) -> Bool {
        return w == a.w && h == a.h
    }

    func operator_plus(_ a:ZSize) -> ZSize    { return ZSize(w + a.w, h + a.h) }
    func operator_minus(_ a:ZSize) -> ZSize   { return ZSize(w - a.w, h - a.h) }
    func operator_times(_ a:ZSize) -> ZSize   { return ZSize(w * a.w, h * a.h) }
    func operator_times(_ a:Double) -> ZSize  { return ZSize(w * a, h * a)     }
    func operator_div(_ a:ZSize) -> ZSize     { return ZSize(w / a.w, h / a.h) }
    func operator_div(_ a:Double) -> ZSize    { return ZSize(w / a, h / a)     }
}

// #swift-only:
func +(me:ZSize, a:ZSize) -> ZSize       { return me.operator_plus(a)      }
func -(me:ZSize, a:ZSize) -> ZSize       { return me.operator_minus(a)     }
func *(me:ZSize, a:ZSize) -> ZSize       { return me.operator_times(a)     }
func *(me:ZSize, a:Double) -> ZSize      { return me.operator_times(a)     }
func /(me:ZSize, a:Double) -> ZSize      { return me.operator_div(a)       }
func /(me:ZSize, a:ZSize) -> ZSize       { return me.operator_div(a)       }
func += (me:inout ZSize, a:ZSize)        { me.w += a.w; me.h += a.h        }
func -= (me:inout ZSize, a:ZSize)        { me.w -= a.w; me.h -= a.h        }
func *= (me:inout ZSize, a:Double)       { me.operator_timesAssign(a)      }
func *= (me:inout ZSize, a:Float)        { me.operator_timesAssign(a)      }
prefix func -(me:ZSize) -> ZSize         { return me.operator_unaryMinus() }
func ==(me:ZSize, a:ZSize) -> Bool       { return me.equals(a)             }
func <(me:ZSize, a:ZSize) -> Bool        { return me.Area() < a.Area()     }
extension ZSize {
    func GetCGSize() -> CGSize       { return CGSize(width:CGFloat(w), height:CGFloat(h)) }
    init(_ s:CGSize)                 { self.init(Double(s.width), Double(s.height)) }
}
// #end
