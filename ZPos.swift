//
//  ZPos.swift
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.

// #package com.github.torlangballe.CetrusAndroid

// https://github.com/seivan/VectorArithmetic/blob/master/VectorArithmetic/VectorArithmetic.swift
// http://practicalswift.com/2014/06/14/the-swift-standard-library-list-of-built-in-functions/

import Darwin
import UIKit

/* #kotlin-raw:
import kotlin.math.*
*/

struct ZPos : Equatable, Codable
{
    var x: Double = 0.0
    var y: Double = 0.0
    
// #swift-only:
    init(_ ax:Double, _ ay:Double) { x = ax; y = ay;   }
    subscript(vertical: Bool) -> Double {
        get { return vertical ? y : x }
        set { if vertical { y = newValue } else { x = newValue } }
    }
    func GetCGPoint() -> CGPoint                  { return CGPoint(x: CGFloat(x), y: CGFloat(y)); }
    init(_ p: CGPoint)                            { self.init(Double(p.x), Double(p.y)) }
/* #kotlin-raw:
     operator fun get(vertical: Boolean) : Double {
        if (vertical) { return y }
        return x
     }
     operator fun set(vertical:Boolean, v:Double) {
        if (vertical) { y = v }
        else { x = v }
     }
*/
    var Size: ZSize { return ZSize(x, y) }
    
    mutating func Set(_ ax: Float, _ ay: Float)   { x = Double(ax); y = Double(ay); }
    mutating func Set(_ ax: Double, _ ay: Double) { x = ax; y = ay; }
    init()                                        { self.init(0.0, 0.0) }
    init(_ ax:Float, _ ay:Float)                  { self.init(Double(ax), Double(ay)) }
    init(_ ax:Int, _ ay:Int)                      { self.init(Double(ax), Double(ay)) }
    init(fp:ZFPos)                                { self.init(Double(fp.x), Double(fp.y)) }
    mutating func Swap()                          { let t = x; x = y; y = t; }
    func GetRot90CW() -> ZPos                     { return ZPos(y, -x); }
    func Dot(_ a: ZPos) -> Double                 { return x * a.x + y * a.y; }
    func Length() -> Double                       { return sqrt(x * x + y * y); }
    func IsNull() -> Bool                         { return x == 0.0 && y == 0.0 }
    func GetNormalized() -> ZPos                  { return self / Length(); }
    func Sign() -> ZPos                           { return ZPos(sign(x), sign(y)) }
    func Abs() -> ZPos                            { return ZPos(x < 0 ? -x : x, y < 0 ? -y : y) }
    func IsSameDirection(_ p: ZPos) -> Bool {
        if self == p {
            return true;
        }
        if sign(Double(p.x)) != sign(Double(x)) || sign(Double(p.y)) != sign(Double(y)) {
            return false;
        }
        if p.y == 0.0 {
            return y == 0.0
        }
        if y == 0.0 {
            return p.y == 0.0
        }
        if x / y == p.x / p.y {
            return true
        }
        return false
    }
    func RotatedCCW(_ angle: Double) -> ZPos {
        let s = sin(angle)
        let c  = cos(angle)
        
        return ZPos(x * c - y * s, x * s + y * c)
    }
    
    func operator_plus(_ a: Double) -> ZPos   { return ZPos(x + a, y + a) }
    func operator_minus(_ a: Double) -> ZPos  { return ZPos(x - a, y - a) }
    func operator_times(_ a: Double) -> ZPos  { return ZPos(x * a, y * a) }
    func operator_div(_ a: Double) -> ZPos    { return ZPos(x / a, y / a) }
    func operator_plus(_ a: ZPos) -> ZPos     { return ZPos(x + a.x, y + a.y) }
    func operator_minus(_ a: ZPos) -> ZPos    { return ZPos(x - a.x, y - a.y) }
    func operator_times(_ a: ZPos) -> ZPos    { return ZPos(x * a.x, y * a.y) }
    func operator_div(_ a: ZPos) -> ZPos      { return ZPos(x / a.x, y / a.y) }
    func operator_unaryMinus() -> ZPos        { return ZPos(-x, -y) }
    func operator_plus(_ s: ZSize) -> ZPos    { return ZPos(x + s.w, y + s.h) }
    func equals(_ a: ZPos) -> Bool            { return x == a.x && y == a.y }
}

// #swift-only:
func +=(me: inout ZPos, a: Double)    { me.x += a; me.y += a            }
func -=(me: inout ZPos, a: Double)    { me.x -= a; me.y -= a            }
func *=(me: inout ZPos, a: Double)    { me.x *= a; me.y *= a            }
func /=(me: inout ZPos, a: Double)    { me.x /= a; me.y /= a            }
func +=(me: inout ZPos, a: ZPos)      { me.x += a.x; me.y += a.y        }
func -=(me: inout ZPos, a: ZPos)      { me.x -= a.x; me.y -= a.y        }
func *=(me: inout ZPos, a: ZPos)      { me.x *= a.x; me.y *= a.y        }
func /=(me: inout ZPos, a: ZPos)      { me.x /= a.x; me.y /= a.y        }
func +(me: ZPos, a: Double) -> ZPos   { return me.operator_plus(a)      }
func -(me: ZPos, a: Double) -> ZPos   { return me.operator_minus(a)     }
func *(me: ZPos, a: Double) -> ZPos   { return me.operator_times(a)     }
func /(me: ZPos, a: Double) -> ZPos   { return me.operator_div(a)       }
func +(me: ZPos, a: ZPos) -> ZPos     { return me.operator_plus(a)      }
func -(me: ZPos, a: ZPos) -> ZPos     { return me.operator_minus(a)     }
func *(me: ZPos, a: ZPos) -> ZPos     { return me.operator_times(a)     }
func /(me: ZPos, a: ZPos) -> ZPos     { return me.operator_div(a)       }
prefix func -(me: ZPos) -> ZPos       { return me.operator_unaryMinus() }
func +(me: ZPos, s: ZSize) -> ZPos    { return me.operator_plus(s)      }
func !=(me:ZPos, a: ZPos) -> Bool     { return !me.equals(a)            }
func ==(me:ZPos, a: ZPos) -> Bool     { return me.equals(a)             }
// #end

struct ZFPos
{
    var x: Float = Float(0.0)
    var y: Float = Float(0.0)
    var DPos: ZPos {
        get { return ZPos(fp:self) }
    }
    // #swift-only:
    init(_ ax:Float, _ ay:Float) { x = ax; y = ay; }
    // #end
    init(_ p:ZPos) { self.init(Float(p.x), Float(p.y)) }
}

func ZForVectors(positions:[ZPos], close:Bool = false, handle:(_ s:ZPos, _ v:ZPos)->Bool) {
    var i = 0
    
    while i < positions.count {
        let s = positions[i]
        var e = ZPos()
        if i == positions.count - 1 {
            if close {
                e = positions[0] - s
            } else {
                break
            }
        } else {
            e = positions[i + 1]
        }
        if !handle(s, e - s) {
            break
        }
        i += 1
    }
}

func ZGetTPositionInPosPath(path:[ZPos], t:Double, close:Bool = false) -> ZPos {
    var len = 0.0
    var resultPos = ZPos()
    
    if t <= 0 {
        return path[0]
    }
    ZForVectors(positions:path, close:close) { (s, v) in
        len += v.Length()
        return true
    }
    if t >= 1 {
        return close ? path[0] : path.last!
    }
    
    let tlen = t * len
    len = 0.0
    ZForVectors(positions:path, close:close) { (s, v) in
        let vlen = v.Length()
        let l = len + vlen
        if l >= tlen {
            let ldiff = tlen - len
            let f = ldiff / vlen
            resultPos = s + v * f
            return false
        }
        len = l
        return true
    }
    
    return resultPos
}
