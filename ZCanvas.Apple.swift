//
//  ZCanvas.swift
//
//  Created by Tor Langballe on /21/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#endif

typealias ZMatrix = CGAffineTransform
typealias ZCanvasBlendMode = CGBlendMode

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

class ZCanvas {
    var context: CGContext
    
    init(context c: CGContext) {
        context = c
    }
    
    init() {
        #if !os(macOS)
        context = UIGraphicsGetCurrentContext()!
        #else
        context = NSGraphicsContext.current!.cgContext
        #endif
    }
    
    func SetColor(_ color: ZColor, opacity:Double = -1.0) {
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
    
    #if !os(macOS)
    @discardableResult func DrawImage(_ image: ZImage, destRect: ZRect, align:ZAlignment = ZAlignment.None, opacity:Float32 = 1.0, blendMode:ZCanvasBlendMode = .normal, corner:Double? = nil, margin:ZSize = ZSize()) -> ZRect {
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
    #endif
    
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
    
    func SetDropShadow(_ delta:ZSize = ZSize(3, 3), blur:Float32 = 3, color:ZColor = ZColor.Black()) {
        let moffset = delta.GetCGSize()    //Mac:    moffset.height *= -1;
        context.setShadow(offset: moffset, blur: CGFloat(blur), color: color.color.cgColor)
        //    CGContextBeginTransparencyLayer(context, nil)
    }
    
    func SetDropShadowOff(opacity:Float32 = -1) {
        //        CGContextEndTransparencyLayer(context)
        context.setShadow(offset: CGSize.zero, blur: 0, color: nil);
        if opacity != 1 {
            context.setAlpha(CGFloat(opacity))
        }
    }
    
    func createGradient(colors:[ZColor], locations:[Float] = [Float]()) -> CGGradient? {
        let cgColors = colors.map { $0.color.cgColor }
        var locs = [CGFloat]()
        if locations.isEmpty {
            for i in 0...colors.count {
                locs.append(CGFloat(i) / CGFloat(colors.count))
            }
        } else {
            locs = locations.map { CGFloat($0) }
        }
        return CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors as CFArray, locations: &locs)
    }
    
    func DrawGradient(path:ZPath? = nil, colors:[ZColor], pos1:ZPos, pos2:ZPos, locations:[Float] = [Float]()) {
        PushState()
        if path != nil {
            self.ClipPath(path!)
        }
        if let gradient = createGradient(colors:colors, locations:locations) {
            context.drawLinearGradient(gradient, start: pos1.GetCGPoint(), end: pos2.GetCGPoint(), options: CGGradientDrawingOptions(rawValue:CGGradientDrawingOptions.drawsBeforeStartLocation.rawValue | CGGradientDrawingOptions.drawsBeforeStartLocation.rawValue))
            PopState()
        }
    }
    
    func DrawRadialGradient(path:ZPath? = nil, colors:[ZColor], center:ZPos, radius:Double, endCenter:ZPos? = nil, startRadius:Double = 0, locations:[Float] = [Float]()) {
        PushState()
        if path != nil {
            //            self.ClipPath(path!)
        }
        if let gradient = createGradient(colors:colors, locations:locations) {
//            let c = UIGraphicsGetCurrentContext()
            context.drawRadialGradient(gradient, startCenter:center.GetCGPoint(), startRadius:CGFloat(startRadius), endCenter:(endCenter == nil ? center : endCenter!).GetCGPoint(), endRadius:CGFloat(radius), options: CGGradientDrawingOptions())
        }
        PopState()
    }
}

/*
 func gradientFunction(inInfo:UnsafeMutablePointer<Void>, input:UnsafeMutablePointer<CGFloat>, output:UnsafeMutablePointer<CGFloat>) -> Void {
 var col = [ZColor](inInfo)
 var d = input[0]
 
 c1 = (ZFRGBAColor *)inInfo;
 c2 = c1 + 1;
 d = in[0];
 
 out[0] = c1->r * d + c2->r * (1 - d);
 out[1] = c1->g * d + c2->g * (1 - d);
 out[2] = c1->b * d + c2->b * (1 - d);
 out[3] = c1->a * d + c2->a * (1 - d);
 }
 func DrawGradient(path:ZPath, cola:ZColor, colb:ZColor, posa:ZPos, posb:ZPos, before:Bool, after:Bool, strokeWidth:Float32) {
 let callbacks = CGFunctionCallbacks(version:0, evaluate:func, releaseInfo:nil)
 CGShadingRef        cgshading;
 var            cols: [ZColor]
 
 cols[0] = ZFRGBAColor(cola);
 cols[1] = ZFRGBAColor(colb);
 var cgfunction = CGFunctionCreate(&cols, 1, NULL, 4, NULL, &callbacks);
 if(cgfunction)
 {
 CGColorSpaceRef cgspace;
 
 cgspace = CGColorSpaceCreateDeviceRGB();
 cgshading = ::CGShadingCreateAxial(cgspace,
 MacZPosToCGPoint(posb),
 MacZPosToCGPoint(posa),
 cgfunction,
 before,
 after);
 CGColorSpaceRelease(cgspace);
 
 if(cgshading)
 {
 canvas->PushState();
 if(strokewidth > 0)
 {
 setPath((CGContextRef)canvas->GetPF()->context, path);
 ::CGContextSetLineWidth((CGContextRef)canvas->GetPF()->context, strokewidth);
 ::CGContextReplacePathWithStrokedPath((CGContextRef)canvas->GetPF()->context);
 ::CGContextEOClip((CGContextRef)canvas->GetPF()->context);
 }
 else
 canvas->Clip(path);
 ::CGContextDrawShading((CGContextRef)canvas->GetPF()->context, cgshading);
 ::CGShadingRelease(cgshading);
 canvas->PopState();
 }
 ::CGFunctionRelease(cgfunction);
 }
 }
 */



