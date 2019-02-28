//
//  ZBallSwitch.swift
//
//  Created by Tor Langballe on /14/11/15.
//
// #package com.github.torlangballe.cetrusandroid

import UIKit

class ZBallSwitch: ZCustomView {
    var on: Bool
    var color = ZColor.White()

    init(value:Bool = false) {
        on = value
        super.init(name:"ZSwitch")
        
        minSize = ZSize(44.0, 44.0) * ZScreen.SoftScale
        HandlePressedInPosFunc = { [weak self] (pos) in
            self!.Value = !self!.on
            ZPerformAfterDelay(0.1) { [weak self] () in
                self?.HandleValueChangedFunc?()
            }
        }
//        isAccessibilityElement = true
        canFocus = true
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let path = ZPath()
        
        if IsFocused {
            ZFocus.Draw(canvas, rect:rect, corner:rect.size.w / 2.0)
        }
        let r = rect.Expanded(-6.0 * ZScreen.SoftScale)
        canvas.SetColor(color.OpacityChanged(Usable ? 1.0 : 0.5))
        path.AddOval(inrect:r.Expanded(-1.0))
        canvas.StrokePath(path, width:2.0 * ZScreen.SoftScale)
        if on {
            path.Empty()
            let radius = r.size.w / 2.0 - 4.0 * ZScreen.SoftScale
            path.ArcDegFromCenter(r.Center, radius:radius)
            canvas.FillPath(path)
        }
    }

    var Value: Bool {
        get { return on }
        set {
            on = newValue
            Expose()
        }
    }
    
    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
}
