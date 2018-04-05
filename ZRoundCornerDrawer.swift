//
//  ZRoundCornerDrawer.swift
//  Zed
//
//  Created by Tor Langballe on /29/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

private func isDef(_ p: ZPos) -> Bool {
    return p.x != 0xFFFFFF
}

class ZRoundCornerDrawer {
    let Undefined = Double(MAXFLOAT)
    
    private var s1, s2, p1, p2: ZPos
    private var startRound: Bool
    private var first, isClose: Bool
    
    var radius: Double
    var path: ZPath
    
    init(radius:Double = 10, path:ZPath = ZPath(), close:Bool = true) {
        self.radius = radius
        self.path = path
        p1 = ZPos(Undefined, Undefined)
        p2 = ZPos(Undefined, Undefined)
        s1 = ZPos(Undefined, Undefined)
        s2 = ZPos(Undefined, Undefined)
        first = true
        startRound = false
        isClose = close
        Empty()
    }
    func MoveTo(_ pos: ZPos, isround: Bool) {
        p2 = pos
        s1 = pos
        p1 = ZPos(Undefined, Undefined)
        p2 = ZPos(Undefined, Undefined)
        if(!isClose) {
            path.MoveTo(pos)
            first = false
        } else {
            startRound = isround
            first = true
        }
    }
    func LineTo(_ pos: ZPos, isround:Bool = true) {
        
        var d1, d2: ZPos
        
        if !isDef(s1) {
            s1 = pos
            startRound = isround
        } else  if !isDef(s2) {
            s2 = pos
        }
        if isDef(p1) && isDef(p2) {
            d1 = -((p2 - p1).GetNormalized())
            d2 = ((pos - p2).GetNormalized())
            Draw(path, p: p2, d1: d1, d2: d2, r: radius, moveto: first)
            first = false
        }
        if isround {
            p1 = p2
        } else {
            if first {
                path.MoveTo(pos)
            } else {
                path.LineTo(pos)
            }
            first = false
            p1 = ZPos(Undefined, Undefined)
        }
        p2 = pos
    }
    func End() {
        if isClose {
            if startRound {
                LineTo(s1, isround:true)
                LineTo(s2, isround:true)
            } else {
                path.LineTo(s1)
            }
        } else {
            path.LineTo(p2)
        }
        if isClose {
            path.Close()
        }
    }
    func Empty() {
        p1 = ZPos(Undefined, Undefined)
        p2 = ZPos(Undefined, Undefined)
        s1 = ZPos(Undefined, Undefined)
        s2 = ZPos(Undefined, Undefined)
        startRound = false
        path.Empty()
    }
    final func Draw(_ path:ZPath, p:ZPos, d1:ZPos, d2:ZPos, r:Double, moveto:Bool)
    {
        var s1, s2: ZPos
    
        if(r != 0) {
            s1 = p + d1 * r
            s2 = p + d2 * r
            if(moveto) {
                path.MoveTo(s1)
            } else {
                path.LineTo(s1)
            }
            path.BezierTo(s1, c2: p, end: s2)
        } else {
            path.LineTo(p)
        }
    }
}
