//
//  ZCanvasExtra.swift
//  Zed
//
//  Created by Tor Langballe on /29/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

extension ZCanvas {
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
            let c = UIGraphicsGetCurrentContext()
            c?.drawLinearGradient(gradient, start: pos1.GetCGPoint(), end: pos2.GetCGPoint(), options: CGGradientDrawingOptions(rawValue:CGGradientDrawingOptions.drawsBeforeStartLocation.rawValue | CGGradientDrawingOptions.drawsBeforeStartLocation.rawValue))
            PopState()
        }
    }
    
    func DrawRadialGradient(path:ZPath? = nil, colors:[ZColor], center:ZPos, radius:Double, endCenter:ZPos? = nil, startRadius:Double = 0, locations:[Float] = [Float]()) {
        PushState()
        if path != nil {
            //            self.ClipPath(path!)
        }
        if let gradient = createGradient(colors:colors, locations:locations) {
            let c = UIGraphicsGetCurrentContext()
            c?.drawRadialGradient(gradient, startCenter:center.GetCGPoint(), startRadius:CGFloat(startRadius), endCenter:(endCenter == nil ? center : endCenter!).GetCGPoint(), endRadius:CGFloat(radius), options: CGGradientDrawingOptions())
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
    
    
}
*/
