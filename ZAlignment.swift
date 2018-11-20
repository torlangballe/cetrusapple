//
//  ZAlignment.swift
//  Cetrus
//
//  Created by Tor Langballe on /23/9/14.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation

public struct ZAlignment : OptionSet, CustomDebugStringConvertible, CustomStringConvertible {
    
    public var rawValue: Int
    
    static let None = ZAlignment(rawValue: 0)
    static let Left = ZAlignment(rawValue: 1)
    static let HorCenter = ZAlignment(rawValue: 2)
    static let Right = ZAlignment(rawValue: 4)
    static let Top = ZAlignment(rawValue: 8)
    static let VertCenter = ZAlignment(rawValue: 16)
    static let Bottom = ZAlignment(rawValue: 32)
    static let HorExpand = ZAlignment(rawValue: 64)
    static let VertExpand = ZAlignment(rawValue: 128)
    static let HorShrink = ZAlignment(rawValue: 256)
    static let VertShrink = ZAlignment(rawValue: 512)
    static let HorOut = ZAlignment(rawValue: 1024)
    static let VertOut = ZAlignment(rawValue: 2048)
    static let NonProp = ZAlignment(rawValue: 4096)
    static let HorJustify = ZAlignment(rawValue: 8192)
    static let MarginIsOffset = ZAlignment(rawValue: 16384)
    static let ScaleToFitProportionally = ZAlignment(rawValue: 32768)
    
    static let Center = HorCenter|VertCenter
    static let Expand = HorExpand|VertExpand
    static let Shrink = HorShrink|VertShrink
    static let HorScale = HorExpand|HorShrink
    static let VertScale = VertExpand|VertShrink
    static let Scale = HorScale|VertScale
    static let Out = HorOut|VertOut
    static let Vertical = Top|VertCenter|Bottom|VertExpand|VertShrink|VertOut
    static let Horizontal = Left|HorCenter|Right|HorExpand|HorShrink|HorOut
    
    // #swift-only:
    public init(rawValue: Int) { self.rawValue = rawValue }
    // #end
    
    init(str:String) {
        self.init(rawValue:stringToRaw(str))
    }

    init(fromVector:ZPos) {
        self.init(rawValue:rawFromVector(fromVector))
    }

    func FlippedVertical() -> ZAlignment {
        var r = self
        r.AndWith(ZAlignment.Horizontal)
        if self & ZAlignment.Top { r.UnionWith(ZAlignment.Bottom) }
        if self & ZAlignment.Bottom { r.UnionWith(ZAlignment.Top) }
        return r
    }
    func FlippedHorizontal() -> ZAlignment {
        var r = self
        r.AndWith(ZAlignment.Vertical)
        if self & ZAlignment.Left { r.UnionWith(ZAlignment.Right) }
        if self & ZAlignment.Right { r.UnionWith(ZAlignment.Left) }
        return r
    }
    func Subtracted(_ sub:ZAlignment) -> ZAlignment {
        return ZAlignment(rawValue:self.rawValue & ZBitwiseInvert(sub.rawValue))
    }
    subscript(vertical:Bool) -> ZAlignment {
        if vertical {
            return self.Subtracted(ZAlignment.Horizontal | ZAlignment.HorExpand | ZAlignment.HorShrink | ZAlignment.HorOut)
        }
        return self.Subtracted(ZAlignment.Vertical | ZAlignment.VertExpand | ZAlignment.VertShrink | ZAlignment.VertOut)
    }
    
    public var description: String {
        get { return StringStorage }
    }
    
    var StringStorage:String {
        var parts = [String]()
        if self & ZAlignment.Left { parts.append("left") }
        if self & ZAlignment.HorCenter { parts.append("horcenter") }
        if self & ZAlignment.Right { parts.append("right") }
        if self & ZAlignment.Top { parts.append("top") }
        if self & ZAlignment.VertCenter { parts.append("vertcenter") }
        if self & ZAlignment.Bottom { parts.append("bottom") }
        if self & ZAlignment.HorExpand { parts.append("horexpand") }
        if self & ZAlignment.VertExpand { parts.append("vertexpand") }
        if self & ZAlignment.HorShrink { parts.append("horshrink") }
        if self & ZAlignment.VertShrink { parts.append("vertshrink") }
        if self & ZAlignment.HorOut { parts.append("horout") }
        if self & ZAlignment.VertOut { parts.append("vertout") }
        if self & ZAlignment.NonProp { parts.append("nonprop") }
        if self & ZAlignment.HorJustify { parts.append("horjustify") }
        return ZStr.Join(parts, sep:" ")
    }
    
    public var debugDescription: String { //
        return StringStorage
    }
    
    mutating func UnionWith(_ a:ZAlignment) {
        rawValue = rawValue | a.rawValue
    }

    mutating func AndWith(_ a:ZAlignment) {
        rawValue = rawValue & a.rawValue
    }
}

// #swift-only:
func |(a:ZAlignment, b:ZAlignment) -> ZAlignment { return ZAlignment(rawValue: a.rawValue | b.rawValue) }
func &(a:ZAlignment, b:ZAlignment) -> Bool       { return (a.rawValue & b.rawValue) != 0                }
/* #kotlin-raw:
infix fun ZAlignment.or(a: ZAlignment) : ZAlignment =
    ZAlignment(rawValue = rawValue or a.rawValue)
infix fun ZAlignment.and(a: ZAlignment) : Boolean =
    ((this.rawValue and a.rawValue) != 0)
*/

private func stringToRaw(_ str:String) -> Int {
    var a = 0
    for s in ZStr.Split(str, sep:" ") {
        switch s {
        case "left":
            a = a | ZAlignment.Left.rawValue
        case "horcenter":
            a = a | ZAlignment.HorCenter.rawValue
        case "right":
            a = a | ZAlignment.Right.rawValue
        case "top":
            a = a | ZAlignment.Top.rawValue
        case "vertcenter":
            a = a | ZAlignment.VertCenter.rawValue
        case "bottom":
            a = a | ZAlignment.Bottom.rawValue
        case "horexpand":
            a = a | ZAlignment.HorExpand.rawValue
        case "vertexpand":
            a = a | ZAlignment.VertExpand.rawValue
        case "horshrink":
            a = a | ZAlignment.HorShrink.rawValue
        case "vertshrink":
            a = a | ZAlignment.VertShrink.rawValue
        case "horout":
            a = a | ZAlignment.HorOut.rawValue
        case "vertout":
            a = a | ZAlignment.VertOut.rawValue
        case "nonprop":
            a = a | ZAlignment.NonProp.rawValue
        case "horjustify":
            a = a | ZAlignment.HorJustify.rawValue
        default:
            break
        }
    }
    return a
}

private func rawFromVector(_ vector:ZPos) -> Int {
    var raw = 0
    var angle = ZMath.PosToAngleDeg(vector)
    if angle < 0 {
        angle += 360
    }
    if angle < 45 * 0.5 {
        raw = ZAlignment.Right.rawValue
    } else if angle < 45 * 1.5 {
        raw = ZAlignment.Right.rawValue | ZAlignment.Top.rawValue
    } else if angle < 45 * 2.5 {
        raw = ZAlignment.Top.rawValue
    } else if angle < 45 * 3.5 {
        raw = ZAlignment.Top.rawValue | ZAlignment.Left.rawValue
    } else if angle < 45 * 4.5 {
        raw = ZAlignment.Left.rawValue
    } else if angle < 45 * 5.5 {
        raw = ZAlignment.Left.rawValue | ZAlignment.Bottom.rawValue
    } else if angle < 45 * 6.5 {
        raw = ZAlignment.Bottom.rawValue
    } else if angle < 45 * 7.5 {
        raw = ZAlignment.Bottom.rawValue | ZAlignment.Right.rawValue
    } else {
        raw = ZAlignment.Right.rawValue
    }
    return raw
}

