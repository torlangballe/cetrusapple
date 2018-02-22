//
//  ZAlignment.swift
//  Cetrus
//
//  Created by Tor Langballe on /23/9/14.
//

import Foundation

struct ZAlignment : OptionSet, CustomDebugStringConvertible, CustomStringConvertible {
    
    var rawValue: Int
    
    static let None = ZAlignment(rawValue: 0)                 // 0
    static let Left = ZAlignment(rawValue: 1<<0)              // 1
    static let HorCenter = ZAlignment(rawValue: 1<<1)         // 2
    static let Right = ZAlignment(rawValue: 1<<2)             // 4
    static let Top = ZAlignment(rawValue: 1<<3)               // 8
    static let VertCenter = ZAlignment(rawValue: 1<<4)        // 16
    static let Bottom = ZAlignment(rawValue: 1<<5)            // 32
    static let HorExpand = ZAlignment(rawValue: 1<<6)         // 64
    static let VertExpand = ZAlignment(rawValue: 1<<7)        // 128
    static let HorShrink = ZAlignment(rawValue: 1<<8)         // 256
    static let VertShrink = ZAlignment(rawValue: 1<<9)        // 512
    static let HorOut = ZAlignment(rawValue: 1<<10)           // 1024
    static let VertOut = ZAlignment(rawValue: 1<<11)          // 2048
    static let NonProp = ZAlignment(rawValue: 1<<12)          // 4096
    static let HorJustify = ZAlignment(rawValue: 1<<13)       // 8192
    static let MarginIsOffset = ZAlignment(rawValue: 1<<14)   // 16384
    static let ScaleToFitProportionally = ZAlignment(rawValue: 1<<15)   // 32768
    
    static let Center = HorCenter|VertCenter
    static let Expand = HorExpand|VertExpand
    static let Shrink = HorShrink|VertShrink
    static let HorScale = HorExpand|HorShrink
    static let VertScale = VertExpand|VertShrink
    static let Scale = HorScale|VertScale
    static let Out = HorOut|VertOut
    static let Vertical = Top|VertCenter|Bottom|VertExpand|VertShrink|VertOut
    static let Horizontal = Left|HorCenter|Right|HorExpand|HorShrink|HorOut
    
    init(rawValue: Int) { self.rawValue = rawValue }

    init(string:String) {
        var a = 0
        for s in string.split(separator:" ") {
            switch s {
            case "left":
                a |= ZAlignment.Left.rawValue
            case "horcenter":
                a |= ZAlignment.HorCenter.rawValue
            case "right":
                a |= ZAlignment.Right.rawValue
            case "top":
                a |= ZAlignment.Top.rawValue
            case "vertcenter":
                a |= ZAlignment.VertCenter.rawValue
            case "bottom":
                a |= ZAlignment.Bottom.rawValue
            case "horexpand":
                a |= ZAlignment.HorExpand.rawValue
            case "vertexpand":
                a |= ZAlignment.VertExpand.rawValue
            case "horshrink":
                a |= ZAlignment.HorShrink.rawValue
            case "vertshrink":
                a |= ZAlignment.VertShrink.rawValue
            case "horout":
                a |= ZAlignment.HorOut.rawValue
            case "vertout":
                a |= ZAlignment.VertOut.rawValue
            case "nonprop":
                a |= ZAlignment.NonProp.rawValue
            case "horjustify":
                a |= ZAlignment.HorJustify.rawValue
            default:
                break
            }
        }
        self.rawValue = a
    }

    func FlippedVertical() -> ZAlignment {
        var r = (rawValue & ZAlignment.Horizontal.rawValue)
        if self & ZAlignment.Top { r |= ZAlignment.Bottom.rawValue }
        if self & ZAlignment.Bottom { r |= ZAlignment.Top.rawValue }
        return ZAlignment(rawValue:r)
    }
    func FlippedHorizontal() -> ZAlignment {
        var r = (rawValue & ZAlignment.Vertical.rawValue)
        if self & ZAlignment.Left { r |= ZAlignment.Right.rawValue }
        if self & ZAlignment.Right { r |= ZAlignment.Left.rawValue }
        return ZAlignment(rawValue:r)
    }
    func Subtracted(_ sub:ZAlignment) -> ZAlignment {
        return ZAlignment(rawValue:self.rawValue & ~sub.rawValue)
    }
    subscript(vertical:Bool) -> ZAlignment {
        if vertical {
            return self.Subtracted(.Horizontal | .HorExpand | .HorShrink | .HorOut)
        }
        return self.Subtracted(.Vertical | .VertExpand | .VertShrink | .VertOut)
    }
    
    var description: String {
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
        return ZStrUtil.Join(parts, sep:" ")
    }
    
    var debugDescription: String { //
        return StringStorage
    }
    
    init(fromVector:ZPos) {
        var angle = ZMath.PosToAngleDeg(fromVector)
        if angle < 0 {
            angle += 360
        }
        if angle < 45 * 0.5 {
            rawValue = ZAlignment.Right.rawValue
        } else if angle < 45 * 1.5 {
            rawValue = ZAlignment.Right.rawValue | ZAlignment.Top.rawValue
        } else if angle < 45 * 2.5 {
            rawValue = ZAlignment.Top.rawValue
        } else if angle < 45 * 3.5 {
            rawValue = ZAlignment.Top.rawValue | ZAlignment.Left.rawValue
        } else if angle < 45 * 4.5 {
            rawValue = ZAlignment.Left.rawValue
        } else if angle < 45 * 5.5 {
            rawValue = ZAlignment.Left.rawValue | ZAlignment.Bottom.rawValue
        } else if angle < 45 * 6.5 {
            rawValue = ZAlignment.Bottom.rawValue
        } else if angle < 45 * 7.5 {
            rawValue = ZAlignment.Bottom.rawValue | ZAlignment.Right.rawValue
        } else {
            rawValue = ZAlignment.Right.rawValue
        }
    }
}

func |(a:ZAlignment, b:ZAlignment) -> ZAlignment { return ZAlignment(rawValue: a.rawValue | b.rawValue) }
func &(a:ZAlignment, b:ZAlignment) -> Bool       { return (a.rawValue & b.rawValue) != 0                }
func |=(me:inout ZAlignment, a:ZAlignment)       { me.rawValue |= a.rawValue }

