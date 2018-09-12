//
//  ZShapeView.swift
//
//  Created by Tor Langballe on /22/10/15.
//

// #package com.github.torlangballe.CetrusAndroid

import UIKit

class ZShapeView: ZContainerView, ZImageLoader {
    enum ShapeType:String { case circle = "circle", rectangle = "rectange", roundRect = "roundrect", star = "star", none = "" }
    var type = ShapeType.circle
    var strokeWidth:Double = 0.0
    var text: ZTextDraw
    var image: ZImage? = nil
    var imageMargin = ZSize(4.0, 1.0)
    var textXMargin = 0.0
    var imageFill = false
    var imageOpacity: Float = Float(1)
    var ratio = 0.3
    var count = 5
    var strokeColor = ZColor.White()
    var maxWidth:Double = 0.0
    var imageAlign = ZAlignment.Center
    var fillBox = false
    var roundImage = false
    var value:Float = Float(0)
    
    init(type: ShapeType, minSize: ZSize) {
        text = ZTextDraw()
        super.init(name:"ZShapeView")
        self.minSize = minSize
        self.type = type
        foregroundColor = ZColor()
        if type == ZShapeView.ShapeType.roundRect {
            ratio = 0.49
        }
        if type == ZShapeView.ShapeType.star {
            ratio = 0.6
        }
        isAccessibilityElement = true
    }
    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:)") }
    // #end
    
    override func CalculateSize(_ total: ZSize) -> ZSize {
        var s = minSize
        if !text.text.isEmpty {
            var ts = (text.GetBounds().size + ZSize(16.0, 6.0))
            ts.w = ts.w * 1.1 // some strange bug in android doesn't allow *= here...
            s.Maximize(ts)
        }
        if maxWidth != 0.0 {
            s.w = min(s.w, maxWidth)
        }
        if type == ZShapeView.ShapeType.circle {
            s.h = max(s.h, s.w)
        }
        return s
    }
    
    func SetImage(_ image:ZImage?, downloadUrl:String = "") {
        self.image = image
        Expose()
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let path = ZPath()
        var r = LocalRect

        if type == ZShapeView.ShapeType.roundRect {
            r = r.Expanded(ZSize(-1.0, -1.0))
        }
        switch type  {
            case ZShapeView.ShapeType.star:
                path.AddStar(rect:r, points:count, inRatio:ratio)
            
            case ZShapeView.ShapeType.circle:
                path.ArcDegFromCenter(r.Center, radius:r.size.w / 2.0 - strokeWidth/2.0)
            
            case ZShapeView.ShapeType.roundRect:
                var corner = min(r.size.w, r.size.h) * ratio
                corner = min(corner, 15.0)
                path.AddRect(r, corner:ZSize(corner, corner))
            
            case ZShapeView.ShapeType.rectangle:
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
        if strokeWidth != 0.0 {
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
                o *= Float(0.6)
            }
            if imageFill {
                canvas.PushState()
                canvas.ClipPath(path)
                canvas.DrawImage(drawImage!, destRect:r, opacity:o)
                canvas.PopState()
            } else {
                var a = imageAlign | ZAlignment.Shrink
                if fillBox {
                   a = ZAlignment.None
                }
                var corner:Double? = nil
                if roundImage {
                    if type == ZShapeView.ShapeType.roundRect {
                        corner = min(15.0, min(r.size.w, r.size.h) * ratio) - imageMargin.Min()
                    } else if type == ZShapeView.ShapeType.circle {
                        corner = image!.Size.Max()
                    }
                }
                canvas.DrawImage(drawImage!, destRect:r, align:a, opacity:o, corner:corner, margin:imageMargin)
            }
        }
        if(text.text != "") {
            var t = text
            t.color = getStateColor(t.color)
            t.rect = r.Expanded(-(strokeWidth + 2.0)).Expanded(ZSize(-textXMargin, 0.0))
            t.rect.pos.y += 2
            if imageFill {
                canvas.SetDropShadow(ZSize(0.0, 0.0), blur:Float(2))
            }
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

