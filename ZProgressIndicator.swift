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
        //        backgroundColor = UIColor.greenColor()
    }

    override func HandleClosing() {
        ZDebug.Print("HandleClosing progress")
        timer.Stop()
    }
    
    func SetUpdate(_ update:(()->Float)? = nil) {
        if update != nil {
            timer.Set(0.2, owner:self) { [weak self] () in
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
        path.ArcDegFromToFromCenter(center, radius:radius)
        canvas.SetColor(ZColor.White(), opacity:0.6)
        canvas.FillPath(path)

        path.Empty()
        path.ArcDegFromToFromCenter(center, radius:radius, degStart:0, degEnd:Double(value) * 360)
        canvas.SetColor(ZColor.Black(), opacity:0.7)
        canvas.StrokePath(path, width:Double(strokeWidth), type:.round)
    }
}
