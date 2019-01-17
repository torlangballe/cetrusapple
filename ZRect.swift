//
//  ZRect.swift
//
//  Created by Tor Langballe on /23/9/14.
//

// #package com.github.torlangballe.cetrusandroid

/* #kotlin-raw:
 import kotlin.math.*
 */

import Foundation

public struct ZRect : ZCopy {
    var pos: ZPos = ZPos()
    var size: ZSize = ZSize()
    
    var IsNull: Bool { return pos.x == 0.0 && pos.y == 0.0 && size.w == 0.0 && size.h == 0.0 }
    var TopLeft: ZPos      { return Min }
    var TopRight: ZPos     { return ZPos(Max.x, Min.y) }
    var BottomLeft: ZPos   { return ZPos(Min.x, Max.y) }
    var BottomRight: ZPos  { return Max }
    
    var MaxPos : ZPos {
        get { return Max }
        set { pos += (newValue - Max) }
    }
    var Max: ZPos {
        get { return ZPos(pos.x + size.w, pos.y + size.h) }
        set {
            size.w = newValue.x - pos.x;
            size.h = newValue.y - pos.y;
        }
    }
    var Min: ZPos {
        get { return pos }
        set {
            size.w += (pos.x - newValue.x)
            size.h += (pos.y - newValue.y)
            pos = newValue.copy()
        }
    }
    mutating func SetMaxX(_ x:Double) {
        size.w = x - pos.x
    }
    mutating func SetMaxY(_ y:Double) {
        size.h = y - pos.y
    }
    mutating func SetMinX(_ x:Double) {
        size.w += (pos.x - x)
        pos.x = x
    }
    mutating func SetMinY(_ y:Double) {
        size.h += (pos.y - y)
        pos.y = y
    }

    var Center : ZPos {
        get { return pos + size / 2.0 }
        set { pos = newValue - size.GetPos() / 2.0 }
    }
    
    static var Null: ZRect { get { return ZRect(0.0, 0.0, 0.0, 0.0) } }

    static func MergeAll(_ rects:[ZRect]) -> [ZRect] {
        var merged = true
        var rold = rects
        while merged {
            var rnew = [ZRect]()
            merged = false;
            for (i, r) in rold.enumerated() {
                var used = false
                for j in i + 1 ..< rold.count {
                    if r.Overlaps(rold[j].Expanded(4.0)) {
                        var n = rects[i]
                        n.UnionWith(rect:rold[j])
                        rnew.append(n)
                        merged = true
                        used = true
                    }
                }
                if !used {
                    rnew.append(r)
                }
            }
            rold = rnew
        }
        return rold
    }
    
    init(_ x0:Float64, _ y0:Float64, _ x1:Float64, _ y1:Float64) { self.init(pos:ZPos(x0, y0), size:ZSize(x1 - x0, y1 - y0)) }
    init(min: ZPos, max: ZPos)                                   { self.init(pos:min, size:ZSize(max.x - min.x, max.y - min.y)) }
    init(rect:ZRect)                                             { self.init(pos:rect.pos, size:rect.size) }
    init(center:ZPos, radius:Double, radiusy:Double? = nil)      { self.init(rect:centerToRect(center:center, radius:radius, radiusy:radiusy)) }

    func Expanded(_ e: ZSize) -> ZRect                           { return ZRect(pos: pos - e.GetPos(), size:size + e * Float64(2.0)); }
    func Expanded(_ n: Float64) -> ZRect                         { return Expanded(ZSize(n, n)) }
    func Centered(_ center:ZPos) -> ZRect                        { return ZRect(pos:center-size.GetPos() / 2.0, size:size) }
    func Overlaps(_ rect:ZRect) -> Bool                          { return rect.Min.x < Max.x && rect.Min.y < Max.y && rect.Max.x > Min.x && rect.Max.y > Min.y }
    func Contains(_ pos:ZPos) -> Bool                            { return pos.x >= Min.x && pos.x <= Max.x && pos.y >= Min.y && pos.y <= Max.y }
    func Align(_ s:ZSize, align:ZAlignment, marg:ZSize = ZSize(), maxSize:ZSize = ZSize()) -> ZRect {
        var x: Double
        var y: Double
        var scalex:Double
        var scaley:Double
        
        var wa = Double(s.w)
        var wf = Double(size.w)
        //        if (align & (ZAlignment.HorShrink|ZAlignment.HorExpand)) {
        if !(align & ZAlignment.MarginIsOffset) {
            wf -= Double(marg.w)
            if align & ZAlignment.HorCenter {
                wf -= Double(marg.w)
            }
        }
        //        }
        var ha = Double(s.h)
        var hf = Double(size.h)
        //        if (align & (ZAlignment.VertShrink|ZAlignment.VertExpand)) {
        if !(align & ZAlignment.MarginIsOffset) {
            hf -= Double(marg.h * 2.0)
        }
        if align == ZAlignment.ScaleToFitProportionally {
            let xratio = wf / wa
            let yratio = hf / ha
            var ns = size
            if xratio != 1.0 || yratio != 1.0 {
                if xratio > yratio {
                    ns = ZSize(wf, ha * xratio)
                } else {
                    ns = ZSize(wa * yratio, hf)
                }
            }
            return ZRect(size:ns).Centered(Center)
        }
        if (align & ZAlignment.HorExpand) && (align & ZAlignment.VertExpand) {
            if (align & ZAlignment.NonProp) {
                wa = wf
                ha = hf
            }
            else
            {
                assert(!(align & ZAlignment.HorOut))                
                scalex = wf / wa
                scaley = hf / ha
                if scalex > 1 || scaley > 1 {
                    if(scalex < scaley) {
                        wa = wf
                        ha *= scalex
                    }
                    else {
                        ha = hf
                        wa *= scaley
                    }
                }
            }
        } else if (align & ZAlignment.NonProp) {
            if (align & ZAlignment.HorExpand) && wa < wf {
                wa = wf
            } else if (align & ZAlignment.VertExpand) && ha < hf {
                ha = hf
            }
        }
        if (align & ZAlignment.HorShrink) && (align & ZAlignment.VertShrink) && !(align & ZAlignment.NonProp) {
            scalex = wf / wa;
            scaley = hf / ha;
            if (align & ZAlignment.HorOut) && (align & ZAlignment.HorOut) {
                if scalex < 1 || scaley < 1 {
                    if(scalex > scaley)
                    {
                        wa = wf;
                        ha *= scalex;
                    }
                    else
                    {
                        ha = hf;
                        wa *= scaley;
                    }
                }
            } else {
                if scalex < 1 || scaley < 1 {
                    if(scalex < scaley)
                    {
                        wa = wf;
                        ha *= scalex;
                    }
                    else
                    {
                        ha = hf;
                        wa *= scaley;
                    }
                }
            }
        } else if (align & ZAlignment.HorShrink) && wa > wf {
            wa = wf;
        }
        //  else
        if (align & ZAlignment.VertShrink) && ha > hf {
            ha = hf;
        }
        
        if maxSize.w != 0.0 {
            wa = min(wa, Double(maxSize.w))
        }
        if maxSize.h != 0.0 {
            ha = min(ha, Double(maxSize.h))
        }
        if (align & ZAlignment.HorOut) {
            if (align & ZAlignment.Left) {
                x = Double(pos.x - marg.w - s.w)
            } else if (align & ZAlignment.HorCenter) {
                //                x = Double(pos.x) - wa / 2.0
                x = Double(pos.x) + (wf - wa) / 2.0
            } else {
                x = Double(Max.x + marg.w)
            }
        }
        else
        {
            if (align & ZAlignment.Left) {
                x = Double(pos.x + marg.w)
            } else if (align & ZAlignment.Right) {
                x = Double(Max.x) - wa - Double(marg.w)
            } else {
                x = Double(pos.x)
                if !(align & ZAlignment.MarginIsOffset) {
                    x += Double(marg.w)
                }
                x = x + (wf - wa) / 2.0
                if align & ZAlignment.MarginIsOffset {
                    x  += Double(marg.w)
                }
            }
        }
        
        if (align & ZAlignment.VertOut) {
            if (align & ZAlignment.Top) {
                y = Double(pos.y - marg.h) - ha;
            } else if (align & ZAlignment.VertCenter) {
                //                y = Double(pos.y) - ha / 2.0;
                y = Double(pos.y) + (hf - ha) / 2.0
            } else {
                y = Double(pos.y + marg.h);
            }
        }
        else
        {
            if (align & ZAlignment.Top) {
                y = Double(pos.y + marg.h);
            } else if (align & ZAlignment.Bottom) {
                y = Double(Max.y) - ha - Double(marg.h);
            } else {
                y = Double(pos.y)
                if !(align & ZAlignment.MarginIsOffset) {
                    y  += Double(marg.h)
                }
                y = y + max(0.0, hf - ha) / 2.0;
                if align & ZAlignment.MarginIsOffset {
                    y += Double(marg.h)
                }
            }
        }
        return ZRect(pos:ZPos(x, y), size:ZSize(wa, ha));
    }
    
    mutating func MoveInto(_ rect:ZRect) {
        pos.x = max(pos.x, rect.pos.x)
        pos.y = max(pos.y, rect.pos.y)
        MaxPos.x = min(MaxPos.x, rect.MaxPos.x)
        MaxPos.y = min(MaxPos.y, rect.MaxPos.y)
    }
    
    /* #kotlin-raw:
    fun copy() : ZRect {
        var r = ZRect()
        r.pos = pos.copy()
        r.size = size.copy()
        return r
    }
    */
    
    mutating func UnionWith(rect:ZRect) {
        if !rect.IsNull {
            if IsNull {
                pos = rect.pos.copy()
                size = rect.size.copy()
            } else {
                if rect.Min.x < Min.x { Min.x = rect.Min.x }
                if rect.Min.y < Min.y { Min.y = rect.Min.y }
                if rect.Max.x > Max.x { SetMaxX(rect.Max.x) }
                if rect.Max.y > Max.y { SetMaxY(rect.Max.y)}
            }
        }
    }
    
    mutating func UnionWith(pos:ZPos) {
        if pos.x > Max.x { Max.x = pos.x }
        if pos.y > Max.y { Max.y = pos.y }
        if pos.x < Min.x { Min.x = pos.x }
        if pos.y < Min.y { Min.y = pos.y }
    }
    
    func operator_plus(_ a:ZRect) -> ZRect        { return ZRect(min:pos + a.pos, max:Max + a.Max) }
    func operator_minus(_ a:ZRect) -> ZRect       { return ZRect(min:pos - a.pos, max:Max - a.Max) }
    func operator_div(_ a:ZSize) -> ZRect         { return ZRect(min:Min / a.GetPos(), max:Max / a.GetPos()) }
//    mutating func operator_plusAssign(_ a:ZRect)  { Min += (a.pos); Max += (a.Max) }
//    mutating func operator_minusAssign(_ a:ZRect) { Min -= (a.pos); Max -= (a.Max) }
    mutating func operator_plusAssign(_ a:ZPos)   { pos += a }
    mutating func vminusAssign(_ a:ZPos)          { pos -= a }
    
    // #swift-only:
    init(pos:ZPos = ZPos(), size:ZSize = ZSize()) { self.pos = pos.copy(); self.size = size.copy() }
    init(_ r: CGRect)                             { pos = ZPos(r.origin); size = ZSize(r.size) }
    func GetCGRect() -> CGRect                    { return CGRect(origin: pos.GetCGPoint(), size:size.GetCGSize())  }
    // #end
}

private func centerToRect(center:ZPos, radius:Double, radiusy:Double? = nil) -> ZRect {
    var s = ZSize(radius, radius)
    if radiusy != nil {
        s = ZSize(radius, radiusy!)
    }
    return ZRect(pos:center - s.GetPos(), size:s * 2.0)
}

// #swift-only:
func +(me:ZRect, a:ZRect) -> ZRect       { return me.operator_plus(a)       }
func -(me:ZRect, a:ZRect) -> ZRect       { return me.operator_minus(a)      }
func +=(me:inout ZRect, a:ZRect)         { me.Min += a.pos; me.Max += a.Max }
func -=(me:inout ZRect, a:ZRect)         { me.Min -= a.pos; me.Max -= a.Max }
func +=(me:inout ZRect, a:ZPos)          { me.operator_plusAssign(a)        }
func /(me:ZRect, a:ZSize) -> ZRect       { return me.operator_div(a)        }
extension ZRect: CustomStringConvertible {
    public var description: String {
        return "[\(Min.x),\(Min.y) \(size.w)x\(size.h)]"
    }
}
// #end



