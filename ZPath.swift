//
//  ZPath.swift
//  Zed
//
//  Created by Tor Langballe on /21/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZPath {
    enum LineType { case square, round, butt }
    enum PartType { case move, line, quadCurveTo, curveTo, close }

    var path: CGMutablePath

    init()                 { path = CGMutablePath()            }
    init(p: ZPath)         { path = p.path.mutableCopy()! }
    
    func Copy(_ p: ZPath)    { path = p.path.mutableCopy()! }
    func Empty()           { path = CGMutablePath()            }
    func IsEmpty() -> Bool { return path.isEmpty              }
    init(rect:ZRect, corner:ZSize = ZSize(), oval:Bool = false) {
        path = CGMutablePath()
        if oval {
            AddOval(inrect:rect)
        } else {
            AddRect(rect, corner:corner)
        }
    }
    
    func GetRect() -> ZRect {
        if IsEmpty() {
            return ZRect()
        }
        return ZRect(path.boundingBox)
    }
    
    func AddOval(inrect:ZRect) {
        path.addEllipse(in:inrect.GetCGRect())
    }
    
    func GetPos() -> ZPos
    {
        let point = path.currentPoint
        return ZPos(point)
    }
    
    func MoveTo(_ pos: ZPos) {
        path.move(to:pos.GetCGPoint())
    }
    
    func LineTo(_ pos: ZPos) {
        path.addLine(to:pos.GetCGPoint())
    }
    
    func BezierTo(_ c1: ZPos, c2: ZPos, end: ZPos = ZPos(-999999, 0)) {
        var e: ZPos
    
        if end.x == -999999 {
            e = c2
        } else {
            e = end
        }
        //        path.addCurve(to:c1.GetCGPoint(), control1:c2.GetCGPoint(), control2:e.GetCGPoint())
        LineTo(c1)
        LineTo(c2)
        LineTo(e)
    }
    
    func ArcTo(_ rect: ZRect, radstart:Double = 0, radDelta:Double = π*2, clockwise:Bool = true) { // this d
        let start = CGFloat(-π/2) + CGFloat(radstart)
        //        let tranform = CGAffineTransform(a: CGFloat(rect.size.w / 2), b: 0, c: 0, d: CGFloat(rect.size.h / 2), tx: CGFloat(center.x), ty: CGFloat(center.y))
        path.addArc(center:rect.Center.GetCGPoint(), radius:CGFloat(rect.size.w / 2), startAngle:start, endAngle:start + CGFloat(radDelta), clockwise:!clockwise) // , transform:tranform)
    }

    func ArcDegFromToFromCenter(_ center: ZPos, radius:Double, degStart:Double = 0, degEnd:Double = 360, radiusy:Double = 0.0) {
        let start = ZMath.DegToRad(degStart)
        let end   = ZMath.DegToRad(degEnd)
        var vradiusy = radiusy
        if vradiusy == 0 {
            vradiusy = radius
        }
        let clockwise = !(start > end)
        let rect = ZRect(size:ZSize(radius * 2, vradiusy * 2)).Centered(center)
        ArcTo(rect, radstart:start, radDelta:end-start, clockwise:clockwise)
    }
    
    func Close() {
        path.closeSubpath()
    }
    
    func AddRect(_ rect: ZRect, corner: ZSize = ZSize()) {
        if rect.size.w != 0 && rect.size.h != 0 {
            if corner.IsNull() || rect.size.w == 0 || rect.size.h == 0 {
                path.addRect(rect.GetCGRect())
            } else {
                var c = corner
                let m = min(rect.size.w, rect.size.h) / 2
                minimize(&c.w, m)
                minimize(&c.h, m)
                path.addRoundedRect(in:rect.GetCGRect(), cornerWidth:CGFloat(c.w), cornerHeight:CGFloat(c.h))
            }
        }
    }
    
    func AddPath(_ p: ZPath, join: Bool, m: ZMatrix?) {
        var transform: CGAffineTransform
        if m != nil {
            transform = m!
        } else {
            transform = CGAffineTransform.identity
        }
        path.addPath(p.path, transform:transform)
    }
    
    func Rotated(deg:Double, origin:ZPos? = nil) -> ZPath {
        var p = CGPoint()
        if origin == nil {
            let bounds = self.path.boundingBox
            p = CGPoint(x:bounds.midX, y:bounds.midY)
        } else {
            p = origin!.GetCGPoint()
        }
        var transform = CGAffineTransform.identity;
        transform = transform.translatedBy(x: p.x, y: p.y)
        transform = transform.rotated(by: CGFloat(Float(ZMath.DegToRad(deg))))
        transform = transform.translatedBy(x: -p.x, y: -p.y)
        let path = ZPath()
        path.path.addPath(self.path, transform:transform)
        return path
    }
    
    /*
    func forEach(_ body: @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        func callback(_ info: UnsafeMutableRawPointer, element: UnsafePointer<CGPathElement>) {
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        path.apply(info: unsafeBody, function: callback as! CGPathApplierFunction)
    }
 */
    
    func forEach(_ handle: @convention(block) (CGPathElement) -> Void) {
        typealias Handle = @convention(block) (CGPathElement) -> Void
        let unsafeHandle = unsafeBitCast(handle, to:UnsafeMutableRawPointer.self)
        path.apply(info:unsafeHandle) { info, unsafeElement in
            let uhandle = unsafeBitCast(info, to: Handle.self)
            let element = unsafeElement.pointee
            uhandle(element)
        }
    }
    
    
    func ForEachPart(_ forPart:(_ part:PartType, _ coords:ZPos...)->Void) {
        forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                forPart(.move, ZPos(element.points[0]))
            case .addLineToPoint:
                forPart(.line, ZPos(element.points[0]))
            case .addQuadCurveToPoint:
                forPart(.quadCurveTo, ZPos(element.points[0]), ZPos(element.points[1]))
            case .addCurveToPoint:
                forPart(.curveTo, ZPos(element.points[0]), ZPos(element.points[1]), ZPos(element.points[2]))
            case .closeSubpath:
                forPart(.close)
            }
        }
    }
    
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

}
