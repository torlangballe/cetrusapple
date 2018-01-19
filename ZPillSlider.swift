//
//  ZCapsuleSlider.swift
//  Zed
//
//  Created by Tor Langballe on /16/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZPillSlider : ZCustomView, ZCustomViewDelegate {
    var slideWidth = 150.0
    var value: Float = 0
    //    var margin = ZRect()
    
    init(value:Float = 0, width:Float = 60) {
        self.value = value // Float(ZMath.Random1())
        super.init(name:"ZPillSlider")
        self.minSize = ZSize(width, 36)
        AddGestureTo(self, type:.pan, dir:ZAlignment.Left)
        self.AddTarget(self, forEventType:.pressed)
    }
    
    override func HandlePressed(_ sender: ZView, pos:ZPos) {
        if value < 0.5 {
            value = 1
        } else {
            value = 0
        }
        //        self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        valueTarget?.handleValueChanged(self)
        Expose()
    }

    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let path = ZPath()
        var h2 = rect.size.h / 2 - 1
        path.AddRect(rect.Expanded(-1), corner:ZSize(h2, h2))
        canvas.SetColor(ZColor.White())
        canvas.StrokePath(path, width:2)
        
        path.Empty()
        h2 -= 4
        var r = rect.Expanded(-5)
        path.AddRect(r, corner:ZSize(h2, h2))
        canvas.SetColor(ZColor(r:0.5, g:0.6, b:0.5, a:0.9))
        r.Max.x = r.Min.x + r.size.w * Double(value)
        let clip = ZPath()
        clip.AddRect(r)
        canvas.PushState()
        canvas.ClipPath(clip)
        canvas.FillPath(path)
        canvas.PopState()
    }
    
    required init?(coder aDecoder:NSCoder) { fatalError("init(coder:) has not been implemented") }
    required override init(name:String) { fatalError("init(name:) has not been implemented") }

    override func HandleGestureType(_ type:ZGestureType, view:ZView, pos:ZPos, delta:ZPos, state:ZGestureState, taps:Int, touches:Int, dir:ZAlignment, velocity:ZPos, gvalue:Float, name:String) -> Bool {
        if type == .pan {
            var v = (delta.x / slideWidth)
            maximize(&v, 0.0)
            minimize(&v, 1.0)
            self.value = Float(v)
            Expose()
            return true
        }
        return super.HandleGestureType(type, view:view, pos:pos, delta:delta, state:state, taps:taps, touches:touches, dir:dir, velocity:velocity, gvalue:gvalue, name:name)
    }
}

