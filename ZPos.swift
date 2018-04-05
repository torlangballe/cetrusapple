//
//  zpos.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

// https://github.com/seivan/VectorArithmetic/blob/master/VectorArithmetic/VectorArithmetic.swift
// http://practicalswift.com/2014/06/14/the-swift-standard-library-list-of-built-in-functions/

import UIKit

struct ZPos : Equatable, Codable
{
    var x: Float64
    var y: Float64
    
    var Size: ZSize {
        return ZSize(x, y)
    }

    mutating func Set(_ ax: Float32, _ ay: Float32) { x = Float64(ax); y = Float64(ay); }
    mutating func Set(_ ax: Float64, _ ay: Float64) { x = ax; y = ay; }
    init()                                        { x = 0; y = 0; }
    init(_ ax:Float32, _ ay:Float32)              { x = Float64(ax); y = Float64(ay); }
    init(_ ax:Double, _ ay:Double)                { x = ax; y = ay;   }
    init(_ ax:Int, _ ay:Int)                      { x = Float64(ax); y = Float64(ay);   }
    init(_ p: CGPoint)                            { x = Float64(p.x); y = Float64(p.y); }
    init(fp:ZFPos)                                { x = Float64(fp.x); y = Float64(fp.y); }
    mutating func Swap()                          { let t = x; x = y; y = t; }
    func GetRot90CW() -> ZPos                     { return ZPos(y, -x); }
    func Dot(_ a: ZPos) -> Float64                { return x * a.x + y * a.y; }
    func Length() -> Float64                      { return sqrt(x * x + y * y); }
    func Abs() -> ZPos                            { return ZPos(x < 0 ? -x : x, y < 0 ? -y : y); }
    func IsNull() -> Bool                         { return x == 0 && y == 0; }
    func GetNormalized() -> ZPos                  { return self / Length(); }
    func GetCGPoint() -> CGPoint                  { return CGPoint(x: CGFloat(x), y: CGFloat(y)); }
    func Sign() -> ZPos                           { return ZPos(sign(x), sign(y)) }
    func IsSameDirection(_ p: ZPos) -> Bool {
        if self == p {
            return true;
        }
        if sign(Double(p.x)) != sign(Double(x)) || sign(Double(p.y)) != sign(Double(y)) {
            return false;
        }
        if p.y == 0.0 {
            return y == 0.0;
        }
        if y == 0.0 {
            return p.y == 0;
        }
        if x / y == p.x / p.y {
            return true;
        }
        return false;
    }
    subscript(vertical: Bool) -> Float64 {
        get {
            if vertical { return y } else { return x }
        }
        set {
            if vertical { y = newValue } else { x = newValue }
        }
    }
    func RotatedCCW(_ angle: Double) -> ZPos {
        let s = sin(angle);
        let c  = cos(angle);
        
        return ZPos(x * c - y * s, x * s + y * c)
    }
}

func +(me: ZPos, a: Float64) -> ZPos   { return ZPos(me.x + a, me.y + a); }
func -(me: ZPos, a: Float64) -> ZPos   { return ZPos(me.x - a, me.y - a); }
func *(me: ZPos, a: Float64) -> ZPos   { return ZPos(me.x * a, me.y * a); }
func /(me: ZPos, a: Float64) -> ZPos   { return ZPos(me.x / a, me.y / a); }
func +(me: ZPos, a: ZPos) -> ZPos      { return ZPos(me.x + a.x, me.y + a.y); }
func -(me: ZPos, a: ZPos) -> ZPos      { return ZPos(me.x - a.x, me.y - a.y); }
func *(me: ZPos, a: ZPos) -> ZPos      { return ZPos(me.x * a.x, me.y * a.y); }
func /(me: ZPos, a: ZPos) -> ZPos      { return ZPos(me.x / a.x, me.y / a.y); }
prefix func -(me: ZPos) -> ZPos        { return ZPos(-me.x, -me.y); }
func +=(me: inout ZPos, a: ZPos)       { me.x += a.x; me.y += a.y; }
func -=(me:inout ZPos, a: ZPos)        { me.x -= a.x; me.y -= a.y; }
func *=(me:inout ZPos, a: ZPos)        { me.x *= a.x; me.y *= a.y; }
func *=(me:inout ZPos, a: Float64)     { me.x *= a; me.y *= a }
func *=(me:inout ZPos, a: Float32)     { me.x *= Float64(a); me.y *= Float64(a) }
func /=(me:inout ZPos, a: ZPos)        { me.x /= a.x; me.y /= a.y }
func /=(me:inout ZPos, a: Float64)     { me.x /= a; me.y /= a }
func !=(me:ZPos, a: ZPos) -> Bool      { return me.x != a.x || me.y != a.y }
func ==(me:ZPos, a: ZPos) -> Bool      { return me.x == a.x && me.y == a.y }
func +(me: ZPos, s: ZSize) -> ZPos     { return ZPos(me.x + s.w, me.y + s.h) }

struct ZFPos
{
    var x: Float32
    var y: Float32
    var DPos: ZPos {
        get { return ZPos(fp:self) }
    }
    init(_ ax:Float, _ ay:Float) { x = ax; y = ay; }
    init(_ p:ZPos)               { x = Float32(p.x); y = Float32(p.y); }
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
    len = 0
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
