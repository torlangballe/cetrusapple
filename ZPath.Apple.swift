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

    init() {
        path = CGMutablePath()
    }
    
    init(p: ZPath) {
        path = p.path.mutableCopy()!
    }
    
    init(rect:ZRect, corner:ZSize = ZSize(), oval:Bool = false) {
        path = CGMutablePath()
        if oval {
            AddOval(inrect:rect)
        } else {
            AddRect(rect, corner:corner)
        }
    }

    func Copy(_ p: ZPath) {
        path = p.path.mutableCopy()!
    }
    
    func Empty() {
        path = CGMutablePath()
    }
    
    func IsEmpty() -> Bool {
        return path.isEmpty
        
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
        path.addCurve(to:c1.GetCGPoint(), control1:c2.GetCGPoint(), control2:e.GetCGPoint())
//        LineTo(c1)
//        LineTo(c2)
//        LineTo(e)
    }
    
    func ArcTo(_ rect: ZRect, degStart:Double = 0, degDelta:Double = 360, clockwise:Bool = true) {
        let start = CGFloat(ZMath.DegToRad(-90 + degStart))
        let end = CGFloat(ZMath.DegToRad(-90 + degStart + degDelta))
        path.addArc(center:rect.Center.GetCGPoint(), radius:CGFloat(rect.size.w / 2), startAngle:start, endAngle:end, clockwise:!clockwise)
    }

    func Close() {
        path.closeSubpath()
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
    
    func forEach(_ handle: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Handle = @convention(block) (CGPathElement) -> Void
        let unsafeHandle = unsafeBitCast(handle, to:UnsafeMutableRawPointer.self)
        path.apply(info:unsafeHandle) { info, unsafeElement in
            let uhandle = unsafeBitCast(info, to: Handle.self)
            let element = unsafeElement.pointee
            uhandle(element)
        }
    }
    
    
    func ForEachPart(_ forPart: @escaping (_ part:PartType, _ coords:ZPos...)->Void) {
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
    func AddRect(_ rect: ZRect, corner: ZSize = ZSize()) {
        if rect.size.w != 0 && rect.size.h != 0 {
            if corner.IsNull() || rect.size.w == 0 || rect.size.h == 0 {
                path.addRect(rect.GetCGRect())
            } else {
                var c = corner
                let m = min(rect.size.w, rect.size.h) / 2
                c.w = min(c.w, m)
                c.h = min(c.h, m)
                path.addRoundedRect(in:rect.GetCGRect(), cornerWidth:CGFloat(c.w), cornerHeight:CGFloat(c.h))
            }
        }
    }
}
