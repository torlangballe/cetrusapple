//
//  ZPath.swift
//
//  Created by Tor Langballe on /21/8/18.
//

import Foundation

extension ZPath {
    func AddStar(rect:ZRect, points:Int, inRatio:Double = 0.3) {
        let c = rect.Center
        let delta = (rect.size.w / 2) - 1
        let inAmount = (1 - inRatio)
        for i in 0 ..< points * 2 {
            let deg = Double(360 * i + 720) / Double(points * 2)
            var d = ZMath.AngleDegToPos(deg) * delta
            if (i & 1) != 0 {
                d *= inAmount
            }
            let p = c + d;
            if i != 0 {
                LineTo(p)
            } else {
                MoveTo(p)
            }
        }
        Close()
    }
    
    func ArcDegFromCenter(_ center: ZPos, radius:Double, degStart:Double = 0.0, degEnd:Double = 360.0, radiusy:Double = 0.0) {
        var vradiusy = radiusy
        if vradiusy == 0.0 {
            vradiusy = radius
        }
        let clockwise = !(degStart > degEnd)
        let rect = ZRect(size:ZSize(radius * 2, vradiusy * 2)).Centered(center)
        ArcTo(rect, degStart:degStart, degDelta:degEnd-degStart, clockwise:clockwise)
    }
}
