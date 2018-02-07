//
//  ZText.swift
//  Zed
//
//  Created by Tor Langballe on /22/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

struct ZText {
    enum DrawType { case fill, stroke, clip }
    enum WrapType { case `default`, word, char, clip, headTruncate, tailTruncate, middleTruncate }

    var type = DrawType.fill
    var wrap = WrapType.default
    //    var AText: NSAttributedString
    var text = ""
    var color = ZColor.Black()
    var alignment = ZAlignment.Center
    var font = ZFont(name: "Helvetica", size: 18)!
    var rect = ZRect()
    var pos:ZPos? = nil
    var lineSpacing: Float = 0.0
    var strokeWidth: Float = 1
    var maxLines: Int = 0

    init() {
    }
    func GetBounds(noWidth:Bool = false) -> ZRect {
        let aStr = NSAttributedString(string:text, attributes:MakeAttributes())
        let opt = NSStringDrawingOptions(rawValue:NSStringDrawingOptions.usesLineFragmentOrigin.rawValue | NSStringDrawingOptions.usesFontLeading.rawValue)
        var cgSize = rect.size.GetCGSize()
        if noWidth {
            cgSize.width = 0
        }
        var size = ZSize(aStr.boundingRect(with:cgSize, options:opt, context:nil).size)

        if maxLines != 0 {
            size.h = Double(font.lineHeight) * Double(maxLines)
        }
//        let size = NSString(string: text).sizeWithAttributes(MakeAttributes())
        return rect.Align(size, align: alignment)
    }

    static func GetNativeWrapMode(_ w: WrapType) -> NSLineBreakMode {
        switch w {
            case WrapType.word          : return NSLineBreakMode.byWordWrapping
            case WrapType.char          : return NSLineBreakMode.byCharWrapping
            case WrapType.headTruncate  : return NSLineBreakMode.byTruncatingHead
            case WrapType.tailTruncate  : return NSLineBreakMode.byTruncatingTail
            case WrapType.middleTruncate: return NSLineBreakMode.byTruncatingMiddle
            default                     : return NSLineBreakMode.byClipping
        }
    }
    
    static func GetTextAdjustment(_ style:ZAlignment) -> NSTextAlignment {
        if (style & ZAlignment.Left)  {
            return NSTextAlignment.left
        } else if (style & ZAlignment.Right) {
            return NSTextAlignment.right
        } else if (style & ZAlignment.HorCenter) {
            return NSTextAlignment.center
        } else if (style & ZAlignment.HorJustify) {
            exit(-1)
        }
        return NSTextAlignment.left
    }

    func MakeAttributes() -> [NSAttributedStringKey: Any] {
        let pstyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        pstyle.lineBreakMode = ZText.GetNativeWrapMode(wrap)
        pstyle.alignment = ZText.GetTextAdjustment(alignment)
//        pstyle.allowsDefaultTighteningForTruncation = true
        if lineSpacing != 0.0 {
            pstyle.maximumLineHeight = font.lineHeight + CGFloat(lineSpacing)
            pstyle.lineSpacing = CGFloat(lineSpacing) // CGFloat(max(0.0, lineSpacing))
        }
    return [ NSAttributedStringKey.font:font,
        NSAttributedStringKey.paragraphStyle:pstyle,
        NSAttributedStringKey.foregroundColor:color.color]
    }

    @discardableResult func Draw(_ canvas: ZCanvas) -> ZRect {
        if text.isEmpty {
            return ZRect(pos:rect.pos, size:ZSize(0, 0))
        }
        
        //!        let attributes = MakeAttributes()
        
        switch type {
            case DrawType.fill:
                //                    CGContextSetFillColorWithColor(canvas.context, canvas->pf->color)
                canvas.context.setTextDrawingMode(CGTextDrawingMode.fill)
            
            case DrawType.stroke:
                canvas.context.setLineWidth(CGFloat(strokeWidth))
                //                CGContextSetFillColorWithColor(canvas.context, canvas->pf->color)
                // CGContextSetStrokeColorWithColor(canvas.context, canvas->pf->color)
                canvas.context.setTextDrawingMode(CGTextDrawingMode.stroke)
            
            case DrawType.clip:
                canvas.context.setTextDrawingMode(CGTextDrawingMode.clip)
        }
        if pos == nil {
            var r = rect
            var ts = GetBounds().size
            ts = ZSize(ceil(ts.w), ceil(ts.h))
            let ra = rect.Align(ts, align:alignment)
            if (alignment & ZAlignment.Top) {
                r.Max.y = ra.Max.y
            } else if (alignment & ZAlignment.Bottom) {
                r.pos.y = r.Max.y - ra.size.h
            } else {
                r.pos.y = ra.pos.y - Double(font.lineHeight) / 20
            }
            
            if (alignment & ZAlignment.HorCenter) {
                //        r = r.Expanded(ZSize(1, 0))
            }
            if (alignment & ZAlignment.HorShrink) {
                //         ScaleFontToFit()
            }
            NSString(string:text).draw(in: r.GetCGRect(), withAttributes:MakeAttributes())
            return rect.Align(ts, align:alignment)
        } else {
            NSString(string:text).draw(at:pos!.GetCGPoint(), withAttributes:MakeAttributes())
            return ZRect.Null
        }
    }
    
    mutating func ScaleFontToFit(minScale:Double=0.5) {
        let w = rect.size.w * 0.95
        let s = GetBounds(noWidth:true).size

        if s.w > w {
            var r = w / s.w
            if r < 0.94 {
                maximize(&r, minScale)
                font = ZFont(name:font.fontName, Double(font.pointSize) * r)!
            }
        } else if s.h > rect.size.h {
            let r = max(0, 5, (rect.size.h / s.h) * 1.01)
            font = ZFont(name:font.fontName, Double(font.pointSize) * r)!
        }
    }
    
    func CreateLayer(margin:ZRect = ZRect()) -> ZTextLayer {
        let textLayer = ZTextLayer()
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.string = text
        textLayer.contentsScale = CGFloat(ZScreen.Scale)
        
        if alignment & .HorCenter {
            textLayer.alignmentMode = kCAAlignmentCenter
        }
        if alignment & .Left {
            textLayer.alignmentMode = kCAAlignmentLeft
        }
        if alignment & .Right {
            textLayer.alignmentMode = kCAAlignmentRight
        }
        textLayer.foregroundColor = color.color.cgColor
        let s = (GetBounds().size + margin.size)
        textLayer.frame = ZRect(size:s).GetCGRect()
        
        return textLayer
    }
}

