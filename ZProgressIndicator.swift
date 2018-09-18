//
//  ZProgressIndicator.swift
//  capsulefm
//
//  Created by Tor Langballe on /11/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

class ZProgressIndicator: ZCustomView {
    var strokeWidth: Int
    var lightStroke = false
    fileprivate var value:Float = 0
    fileprivate var timer = ZRepeater()
    var Value:Float {
        get { return value }
        set {
            value = newValue
            Expose()
        }
    }

    init(size:Int = 32, stroke:Int = 2, value:Float = 0) {
        strokeWidth = stroke
        self.value = value
        super.init(name:"progress")
        minSize = ZSize(size, size)
        isHidden = true
        isOpaque = true
        //        backgroundColor = UIColor.greenColor()
    }

    override func HandleClosing() {
        ZDebug.Print("HandleClosing progress")
        timer.Stop()
    }
    
    func SetUpdate(_ update:(()->Float)? = nil) {
        if update != nil {
            timer.Set(0.2) { [weak self] () in
                let v = update!()
                if v == -1 {
                    return false
                }
                self?.Value = v
                return true
            }
        } else {
            timer.Stop()
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let path = ZPath()
        let radius = (Rect.size.w - Double(strokeWidth)) / 2 - 1
        let center = LocalRect.Center
        
        path.ArcDegFromCenter(center, radius:radius)
        canvas.SetColor(ZColor(white:lightStroke ? 0.4 : 0.8), opacity:1)
        canvas.FillPath(path)

        path.Empty()
//        let a = max(5, Double(value) * 360)
        let a = Double(value) * 360
        path.ArcDegFromCenter(center, radius:radius, degStart:0, degEnd:a)
        canvas.SetColor(ZColor(white:lightStroke ? 0.8 : 0.2), opacity:1)
        canvas.StrokePath(path, width:Double(strokeWidth), type:.round)
    }
}
