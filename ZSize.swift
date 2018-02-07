//
//  ZSize.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

import UIKit

struct ZSize
{
    var w: Float64
    var h: Float64

    init()                           { w = 0; h = 0 }
    init(_ aw:Int, _ ah:Int)         { w = Float64(aw); h = Float64(ah) }
    init(_ aw:Float64, _ ah:Float64) { w = aw; h = ah }
    init(_ aw:Float, _ ah:Float)     { w = Float64(aw); h = Float64(ah) }
    init(_ s:CGSize)                 { w = Float64(s.width); h = Float64(s.height) }
    func GetCGSize() -> CGSize       { return CGSize(width:CGFloat(w), height:CGFloat(h)) }
    func GetPos() -> ZPos          { return ZPos(w, h) }
    func IsNull() -> Bool            { return w == 0.0 && h == 0.0 }
    subscript(vertical:Bool) -> Float64 {
        get {
            if vertical { return h } else { return w }
        }
        set {
            if vertical { h = newValue } else { w = newValue }
        }
    }
    
    func MaxSide() -> Double {
        return max(w, h)
    }

    func EqualSided() -> ZSize {
        let m = max(w, h)
        return ZSize(m, m)
    }
    func Area() -> Float64 {
        return w * h
    }
}

func +(me:ZSize, a:ZSize) -> ZSize       { return ZSize(me.w + a.w, me.h + a.h) }
func -(me:ZSize, a:ZSize) -> ZSize       { return ZSize(me.w - a.w, me.h - a.h) }
func += (me:inout ZSize, a:ZSize)        { me = me + a }
func -= (me:inout ZSize, a:ZSize)        { me = me - a }
func /(me:ZSize, a:Float64) -> ZSize     { return ZSize(me.w / a, me.h / a) }
func /(me:ZSize, a:ZSize) -> ZSize       { return ZSize(me.w / a.w, me.h / a.h) }
func *(me:ZSize, a:Float32) -> ZSize     { return ZSize(me.w * Double(a), me.h * Double(a)) }
func *= (me:inout ZSize, a:Float64)      { me = me * a }
func *= (me:inout ZSize, a:Float32)      { me = me * Float64(a) }
prefix func -(me:ZSize) -> ZSize         { return ZSize(-me.w, -me.h) }
func ==(me:ZSize, a:ZSize) -> Bool       { return me.w == a.w && me.h == a.w }
func *(me:ZSize, a:Float64) -> ZSize     { return ZSize(me.w * Float64(a), me.h * Float64(a)) }
func |=(me:inout ZSize, a:ZSize)         { maximize(&me.w, a.w); maximize(&me.h, a.h) }
func <(me:ZSize, a:ZSize) -> Bool        { return me.w < a.w && me.h < a.h }

