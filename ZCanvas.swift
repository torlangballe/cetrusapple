//
//  ZCanvas.swift
//  Zed
//
//  Created by Tor Langballe on /21/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

typealias ZMatrix = CGAffineTransform

func ZMatrixForRotatingAroundPoint(_ point:ZPos, deg:Double) -> ZMatrix {
    var transform = CGAffineTransform.identity;
    transform = transform.translatedBy(x:CGFloat(point.x), y:CGFloat(point.y))
//    let r = CGAffineTransform.identity.rotated(by:CGFloat(ZMath.DegToRad(deg)))
    transform = transform.rotated(by: CGFloat(ZMath.DegToRad(deg)))
//    transform = transform.concatenating(r)
    transform = transform.translatedBy(x:CGFloat(-point.x), y:CGFloat(-point.y))

    return transform
}

func ZMatrixForRotationDeg(_ deg:Double) -> ZMatrix {
    var transform = CGAffineTransform.identity;
    transform = transform.rotated(by: CGFloat(ZMath.DegToRad(deg)))
    return transform
}

struct ZCanvas {
    var context: CGContext

    init(context c: CGContext) {
        context = c
    }

    init() {
        context = UIGraphicsGetCurrentContext()!
    }

    func SetColor(_ color: ZColor, opacity:Float = -1.0) {
        /*
        if(color.type == ZNColor::TILE)
        {
            static const CGPatternCallbacks callbacks = { 0, &drawImage, NULL };
            
            CGColorSpaceRef patternSpace;
            CGPatternRef    pattern;
            CGFloat         alpha;
            
            alpha = col.a;
            patternSpace = CGColorSpaceCreatePattern(NULL);
            CGContextSetFillColorSpace(conref, patternSpace);
            CGColorSpaceRelease(patternSpace);
            
            pattern = CGPatternCreate(col.bitmaptile->MakeNative(),
                CGRectMake (0, 0, col.bitmaptile->size.w, col.bitmaptile->size.h),
                CGAffineTransformMake (1, 0, 0, 1, col.bitmapOffset.x, col.bitmapOffset.y),
                col.bitmaptile->size.w,
                col.bitmaptile->size.w,
                kCGPatternTilingConstantSpacing,
                IS(colored),
                &callbacks);
            if(stroke)
            CGContextSetStrokePattern(conref, pattern, &alpha);
            else
            CGContextSetFillPattern(conref, pattern, &alpha);
            CGPatternRelease(pattern);
        }
*/
        var vcolor = color
        if opacity != -1 {
            vcolor = vcolor.OpacityChanged(opacity)
        }
        context.setStrokeColor(vcolor.color.cgColor);
        context.setFillColor(vcolor.color.cgColor);
    }
    
    func FillPath(_ path: ZPath, eofill: Bool = false)
    {
        setPath(context, path: path);
        context.fillPath(using:(eofill ? .evenOdd : .winding))
    }
    
    func SetFont(_ font: ZFont, matrix: ZMatrix)
    {
        //    state.font = afont->CreateTransformed(amatrix);
    }
    
    func SetMatrix(_ matrix: ZMatrix)
    {
        var tranform = context.ctm;
        tranform = tranform.inverted();
        tranform = matrix.concatenating(tranform);
        context.concatenate(tranform);
    }
    
    func Transform(_ matrix:ZMatrix)
    {
        context.concatenate(matrix);
    }
    
    func ClipPath(_ path: ZPath, exclude: Bool = false, eofill: Bool = false) {
        setPath(context, path: path)
        context.clip(using:(eofill ? .evenOdd : .winding))
    }
    
    func GetClipRect() -> ZRect {
        return ZRect(context.boundingBoxOfClipPath)
    }

    func StrokePath(_ path: ZPath, width:Double, type: ZPath.LineType = .round) {
        setPath(context, path: path)
        setLineType(context, type: type)
        context.setLineWidth(CGFloat(width))
        context.strokePath()
    }
    
    func DrawPath(_ path: ZPath, strokeColor: ZColor, width :Double, type: ZPath.LineType = .round, eofill: Bool = false) {
        setPath(context, path: path);
        context.setStrokeColor(strokeColor.color.cgColor);
    
        setLineType(context, type: type);
        context.setLineWidth(CGFloat(width));
    
        context.drawPath(using: eofill ? CGPathDrawingMode.eoFillStroke : CGPathDrawingMode.fillStroke);
    }
    
    @discardableResult func DrawImage(_ image: ZImage, destRect: ZRect, align:ZAlignment = ZAlignment.None, opacity:Float32 = 1.0, blendMode:CGBlendMode = .normal, corner:Double? = nil, margin:ZSize = ZSize()) -> ZRect {
        var vdestRect = destRect
        if align != ZAlignment.None {
            vdestRect = vdestRect.Align(ZSize(image.size), align:align, marg:margin)
        } else {
            vdestRect = vdestRect.Expanded(-margin)
        }
        if corner != nil {
            PushState()
            let path = ZPath(rect:vdestRect, corner:ZSize(corner!, corner!))
            ClipPath(path)
        }
        image.draw(in: vdestRect.GetCGRect(), blendMode:blendMode, alpha:CGFloat(opacity))
        if corner != nil {
            PopState()
        }
        return vdestRect
    }
        
    func PushState() {
        context.saveGState();
    }
    
    func PopState() {
        context.restoreGState();
    }
    
    func ClearRect(_ rect: ZRect) {
        context.clear(rect.GetCGRect());
    }
    
    func setLineType(_ c: CGContext, type: ZPath.LineType) {
        var join: CGLineJoin
        var cap: CGLineCap
        
        switch(type) {
        case ZPath.LineType.square:
            join = CGLineJoin.miter
            cap = CGLineCap.square
            
        case ZPath.LineType.round:
            join = CGLineJoin.round
            cap = CGLineCap.round
            
        case ZPath.LineType.butt:
            join = CGLineJoin.bevel
            cap = CGLineCap.butt
        }
        context.setLineJoin(join);
        context.setLineCap(cap);
    }
    
    func setPath(_ c: CGContext, path: ZPath)
    {
        c.beginPath();
        c.addPath(path.path);
    }
}
