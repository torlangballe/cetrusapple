//
//  ZShapeView.swift
//  Zed
//
//  Created by Tor Langballe on /22/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZShapeView: ZContainerView, ZImageLoader {
    enum ShapeType:String { case circle = "circle", rectangle = "rectange", roundRect = "roundrect", star = "star", none = "" }
    var type = ShapeType.circle
    var strokeWidth:Double = 0
    var text: ZText
    var image: ZImage? = nil
    var imageMargin = ZSize(4, 1)
    var textXMargin = 0.0
    var imageFill = false
    var imageOpacity: Float = 1.0
    var ratio = 0.3
    var count = 5
    var strokeColor = ZColor.White()
    var maxWidth:Double = 0
    var imageAlign = ZAlignment.Center
    var fillBox = false
    var roundImage = false
    var value:Float = 0
    
    init(type t: ShapeType, minSize: ZSize) {
        text = ZText()
        super.init(name:"ZShapeView")
        self.minSize = minSize
        self.frame = ZRect(size:minSize).GetCGRect()
        type = t
        foregroundColor = ZColor()
        if type == .roundRect {
            ratio = 0.49
        } else if type == .star {
            ratio = 0.6
        }
        isAccessibilityElement = true
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:)") }
    // override init(name: String) { fatalError("init(name:) has not been implemented") }
    
    override func CalculateSize(_ total: ZSize) -> ZSize {
        var s = minSize
        if !text.text.isEmpty {
            var ts = (text.GetBounds().size + ZSize(16, 6))
            ts.w *= 1.1
            s.Maximize(ts)
        }
        if maxWidth != 0 {
            minimize(&s.w, maxWidth)
        }
        if type == .circle {
            maximize(&s.h, s.w)
        }
        return s
    }
    
    func SetImage(_ image:ZImage?, downloadUrl:String = "") {
        self.image = image
        Expose()
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        
        let path = ZPath()
        var r = LocalRect //.Expanded(-strokeWidth/2)

        if type == .roundRect {
            r = r.Expanded(ZSize(-1, -1))
        }
        switch type  {
            case .star:
                path.AddStar(rect:r, points:count, inRatio:ratio)
            
            case .circle:
                path.ArcDegFromToFromCenter(r.Center, radius:r.size.w / 2 - strokeWidth/2, degStart:0, degEnd:360)
            
            case .roundRect:
                var corner = min(r.size.w, r.size.h) * ratio
                minimize(&corner, 15)
                path.AddRect(r, corner:ZSize(corner, corner))
            
            case .rectangle:
                path.AddRect(r)
            
            default:
                break
        }
        if !foregroundColor.undefined {
            var o = foregroundColor.Opacity
            if !Usable {
                o *= 0.6
            }
            canvas.SetColor(getStateColor(foregroundColor), opacity:o)
            canvas.FillPath(path)
        }
        if strokeWidth != 0 {
            var o = strokeColor.Opacity
            if !Usable {
                o *= 0.6
            }
            canvas.SetColor(getStateColor(strokeColor), opacity:o)
            canvas.StrokePath(path, width:strokeWidth)
        }
        if(image != nil) {
            var drawImage = image
            if isHighlighted {
                drawImage = drawImage!.TintedWithColor(ZColor(white:0.2))
            }
            var o = imageOpacity
            if !Usable {
                o *= 0.6
            }
            if imageFill {
                canvas.PushState()
                canvas.ClipPath(path)
                canvas.DrawImage(drawImage!, destRect:r, opacity:o)
                canvas.PopState()
            } else {
                var a = imageAlign | ZAlignment.Shrink
                if fillBox {
                   a = .None
                }
                var corner:Double? = nil
                if roundImage {
                    if type == .roundRect {
                        corner = min(15, min(r.size.w, r.size.h) * ratio) - imageMargin.Min()
                    } else if type == .circle {
                        corner = image!.Size.Max()
                    }
                }
                canvas.DrawImage(drawImage!, destRect:r, align:a, opacity:o, corner:corner, margin:imageMargin)
            }
        }
        if(text.text != "") {
            var t = text
            t.color = getStateColor(t.color)
            t.rect = r.Expanded(-(strokeWidth + 2)).Expanded(ZSize(-textXMargin, 0))
            t.rect.pos.y += 2
            if imageFill {
                canvas.SetDropShadow(ZSize(0, 0), blur:2)
            }
            // path.Empty(); path.AddRect(r); canvas.SetColor(ZColor.Blue()); canvas.FillPath(path); path.Empty()
            t.Draw(canvas)
            if imageFill {
                canvas.SetDropShadowOff()
            }
        }
    }

    override var accessibilityLabel: String? {
        get {
            if super.accessibilityLabel != nil && !super.accessibilityLabel!.isEmpty {
                return super.accessibilityLabel!
            }
            return text.text
        }
        set {
            super.accessibilityLabel = newValue
        }
    }    
}

