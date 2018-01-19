//
//  zrect.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

import UIKit

struct ZRect
{
    var pos: ZPos
    var size: ZSize
    
    var IsNull: Bool { return pos.x == 0 && pos.y == 0 && size.w == 0 && size.h == 0 }
    var TopLeft: ZPos      { return Min }
    var TopRight: ZPos     { return ZPos(Max.x, Min.y) }
    var BottomLeft: ZPos   { return ZPos(Min.x, Max.y) }
    var BottomRight: ZPos  { return Max }
    static var Null: ZRect { get { return ZRect(0, 0, 0, 0) } }
    
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
            size += (pos - newValue).Size
            pos = newValue
        }
    }
    var Center : ZPos {
        get { return pos + size / 2 }
        set { pos = newValue - size.GetPos() / 2 }
    }

    init()                                                       { pos = ZPos(); size = ZSize() }
    init(_ x0:Float64, _ y0:Float64, _ x1:Float64, _ y1:Float64) { pos = ZPos(x0, y0); size = ZSize(x1 - x0 , y1 - y0) }
    init(_ r: CGRect)                                            { pos = ZPos(r.origin); size = ZSize(r.size) }
    init(min: ZPos, max: ZPos)                                   { pos = min; size = ZSize(max.x - pos.x, max.y - pos.y) }
    init(pos: ZPos = ZPos(0, 0), size: ZSize = ZSize(0, 0))      { self.pos = pos; self.size = size  }
    init(center:ZPos, radiusSize:ZSize)                          { pos = center - radiusSize.GetPos(); size = radiusSize * Float64(2) }
    init(center:ZPos, radius:Double)                             { self.init(center:center, radiusSize:ZSize(radius, radius)) }
    
    func GetCGRect() -> CGRect                                   { return CGRect(origin: pos.GetCGPoint(), size:size.GetCGSize())  }
    func Expanded(_ e: ZSize) -> ZRect                           { return ZRect(pos: pos - e.GetPos(), size:size + e * Float64(2.0)); }
    func Expanded(_ n: Float64) -> ZRect                         { return Expanded(ZSize(n, n)) }
    func Centered(_ center:ZPos) -> ZRect                        { return ZRect(pos:center-size.GetPos()/2, size:size) }
    func Overlaps(_ rect:ZRect) -> Bool                          { return rect.Min.x < Max.x && rect.Min.y < Max.y && rect.Max.x > Min.x && rect.Max.y > Min.y }
    func Contains(_ pos:ZPos) -> Bool                            { return pos.x >= Min.x && pos.x <= Max.x && pos.y >= Min.y && pos.y <= Max.y }
    func Align(_ s:ZSize, align:ZAlignment, marg:ZSize = ZSize(), maxSize:ZSize = ZSize()) -> ZRect {
        var wa, wf, ha, hf, x, y: Double;
        var scalex, scaley: Double;
        
        wa = Double(s.w)
        wf = Double(size.w)
        //        if (align & (ZAlignment.HorShrink|ZAlignment.HorExpand)) {
        if !(align & .MarginIsOffset) {
            wf -= Double(marg.w)
            if align & .HorCenter {
                wf -= Double(marg.w)
            }
        }
        //        }
        ha = Double(s.h)
        hf = Double(size.h)
        //        if (align & (ZAlignment.VertShrink|ZAlignment.VertExpand)) {
        if !(align & .MarginIsOffset) {
            hf -= Double(marg.h * 2)
        }
        if align == .ScaleToFitProportionally {
            let xratio = wf / wa
            let yratio = hf / ha
            var ns = size
            if xratio != 1 || yratio != 1 {
                if xratio > yratio {
                    ns = ZSize(wf, ha * xratio)
                } else {
                    ns = ZSize(wa * yratio, hf)
                }
            }
            return ZRect(size:ns).Centered(Center)
        }
        //        }
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
        
        if maxSize.w != 0 {
            minimize(&wa, Double(maxSize.w))
        }
        if maxSize.h != 0 {
            minimize(&ha, Double(maxSize.h))
        }
        if (align & ZAlignment.HorOut) {
            if (align & ZAlignment.Left) {
                x = Double(pos.x - marg.w - s.w)
            } else if (align & ZAlignment.HorCenter) {
                //                x = Double(pos.x) - wa / 2
                x = Double(pos.x) + (wf - wa) / 2
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
                if !(align & .MarginIsOffset) {
                    x += Double(marg.w)
                }
                x = x + (wf - wa) / 2
                if align & .MarginIsOffset {
                    x += Double(marg.w)
                }
            }
        }
        
        if (align & ZAlignment.VertOut) {
            if (align & ZAlignment.Top) {
                y = Double(pos.y - marg.h) - ha;
            } else if (align & ZAlignment.VertCenter) {
                //                y = Double(pos.y) - ha / 2;
                y = Double(pos.y) + (hf - ha) / 2
            } else {
                y = Double(pos.y + marg.h);
            }
        }
        else
        {
            if (align & .Top) {
                y = Double(pos.y + marg.h);
            } else if (align & .Bottom) {
                y = Double(Max.y) - ha - Double(marg.h);
            } else {
                y = Double(pos.y)
                if !(align & .MarginIsOffset) {
                    y += Double(marg.h)
                }
                y = y + max(0.0, hf - ha) / 2.0;
                if align & .MarginIsOffset {
                    y += Double(marg.h)
                }
            }
        }
        return ZRect(pos:ZPos(x, y), size:ZSize(wa, ha));
    }
    
    static func MergeAll(_ rects:inout [ZRect]) {
        var merged:Bool
        repeat {
            merged = false;
            for (i, r) in rects.enumerated() {
                for j in i + 1 ..< rects.count {
                    if r.Overlaps(rects[j].Expanded(4)) {
                        rects[i] |= rects[j]
                        rects.remove(at: j)
                        merged = true
                    }
                }
            }
        } while merged
    }
    
    mutating func MoveInto(_ rect:ZRect) {
        maximize(&pos.x, rect.pos.x)
        maximize(&pos.y, rect.pos.y)
        minimize(&MaxPos.x, rect.MaxPos.x)
        minimize(&MaxPos.y, rect.MaxPos.y)
    }
}

func +(me:ZRect, a:ZRect) -> ZRect      { return ZRect(min:me.pos + a.pos, max:me.Max + a.Max) }
func -(me:ZRect, a:ZRect) -> ZRect      { return ZRect(min:me.pos - a.pos, max:me.Max - a.Max) }
func +=(me:inout ZRect, a:ZRect)        { me = me + a }
func -=(me:inout ZRect, a:ZRect)        { me = me - a }
func +=(me:inout ZRect, a:ZPos)         { me.pos += a }
func -=(me:inout ZRect, a:ZPos)         { me.pos -= a }
func /(me:ZRect, a:ZSize) -> ZRect      { return ZRect(min:me.Min / a.GetPos(), max:me.Max / a.GetPos()) }

func |=(me:inout ZRect, r:ZRect) {
    if !r.IsNull {
        if me.IsNull {
            me = r
        } else {
            if r.Min.x < me.Min.x { me.Min.x = r.Min.x }
            if r.Min.y < me.Min.y { me.Min.y = r.Min.y }
            if r.Max.x > me.Max.x { me.Max.x = r.Max.x }
            if r.Max.y > me.Max.y { me.Max.y = r.Max.y }
        }
    }
}

func |=(me:inout ZRect, pos:ZPos) {
    if pos.x > me.Max.x { me.Max.x = pos.x }
    if pos.y > me.Max.y { me.Max.y = pos.y }
    if pos.x < me.Min.x { me.Min.x = pos.x }
    if pos.y < me.Min.y { me.Min.y = pos.y }
}

extension ZRect: CustomStringConvertible {
    var description: String {
        return "[\(Min.x),\(Min.y) \(size.w)x\(size.h)]"
    }
}



