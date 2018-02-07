//
//  ZBallSwitch.swift
//  capsulefm
//
//  Created by Tor Langballe on /13/7/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZBallSwitch: ZContainerView {
    var value: Float
    var tinfo = ZText()
    var gap:Double = 8
    var maxWidth:Double = 0
    var color = ZColor.White()
    var activity: ZActivityIndicator? = nil
    var popInView: ZContainerView? = nil
    var popInRectMarg = ZRect()
    var ballSelector: ZBallSelector? = nil
    var inset = 5.0
    
    var BoolValue: Bool {
        get { return value != 0 }
        set {
            value = newValue ? 1 : 0
            Expose()
        }
    }

    init(value:Float = 0, title:String = "") {
        tinfo.text = title
        self.value = value // Float(ZMath.Random1())
        super.init(name:"ballswitch")
        self.minSize = ZSize(36, 36)
        self.AddTarget(self, forEventType:.pressed)
        isAccessibilityElement = true
        AddGestureTo(self, type:.longpress, duration:0.4)
    }

    override var accessibilityLabel: String? {
        get {
            return tinfo.text
        }
        set {
            super.accessibilityLabel = newValue
        }
    }

    override var accessibilityValue: String? {
        get {
            return ZLocale.GetSelected(value == 1)
        }
        set {
            super.accessibilityValue = newValue
        }
    }
    
    override func CalculateSize(_ total: ZSize) -> ZSize {
        var s = tinfo.GetBounds().size
        s.w += minSize.w
        if !tinfo.text.isEmpty {
            s.w += gap
        }
        s.h = minSize.h
        if maxWidth != 0 {
            minimize(&s.w, maxWidth)
        }
        return s - margin.size
    }
    
    override func HandlePressed(_ sender: ZView, pos:ZPos) {
        if value == 0 {
            value = 1
        } else {
            value = 0
        }
        //        self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        Expose()
        PerformAfterDelay(0.1) { () in
            self.valueTarget?.handleValueChanged(self)
        }
    }
    
    override func HandleGestureType(_ type: ZGestureType, view: ZView, pos: ZPos, delta: ZPos, state: ZGestureState, taps: Int, touches: Int, dir: ZAlignment, velocity: ZPos, gvalue: Float, name: String) -> Bool {
        switch type {
        case .longpress:
            if popInView != nil {
                switch state {
                case .began:
                    ballSelector = ZBallSelector(value:value, parent:popInView!, target:self)
                    ballSelector!.value = value
                    for v in popInView!.subviews {
                        if let sv = v as? UIScrollView {
                            sv.panGestureRecognizer.isEnabled = false
                            sv.panGestureRecognizer.isEnabled = true
                        }
                    }

                case .ended:
                    popInView!.RemoveChild(ballSelector!)
                    valueTarget?.handleValueChanged(self)
                    
                case .changed:
                    let v = ballSelector!.SetDistance((pos - LocalRect.Center).Length())
                    if v < 0 {
                        popInView!.RemoveChild(ballSelector!)
                        value = -Float(v)
                        valueTarget?.handleValueChanged(self)
                    } else {
                        value = Float(v)
                    }
                    Expose()
                default:
                    break
                }
            }
            return true
                
        default:
            return false
        }
    }
    
    func SetActivity(_ on:Bool = true) {
        if on {
            activity = ZActivityIndicator()
            Add(activity!, align:.Left | .VertCenter)
            ArrangeChildren()
            activity!.Start()
        } else if activity != nil {
            activity!.Start(false)
            RemoveChild(activity!)
            activity = nil
        }
        Expose()
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let path = ZPath()
        var r = rect + margin
        var text = tinfo
        r.size.w = minSize.w

        if activity == nil {
            canvas.SetColor(color.OpacityChanged(Usable ? 1 : 0.5))
            path.AddOval(inrect:r.Expanded(-1))
            canvas.StrokePath(path, width:2)
            if value != 0 {
                path.Empty()
                let radius = r.Expanded(-inset).size.w / 2 * Double(value)
                path.ArcDegFromToFromCenter(r.Center, radius:radius)
                //                path.ArcTo(r.Expanded(-5), radstart:0, radDelta:Float(π) * 2)
                canvas.FillPath(path)
            }
        }
        text.rect = rect
        text.rect.Min.x = minSize.w + gap
        text.color = color
        text.alignment = .Left | .VertCenter
        text.ScaleFontToFit(minScale:0.8)
        text.Draw(canvas)
    }
    
    required init?(coder aDecoder:NSCoder) { fatalError("init(coder:) has not been implemented") }    
}

class ZBallSelector : ZContainerView {
    let rin:Double = 30
    let marg:Double = 3
    let rfull:Double = 120
    var rout:Double = 0
    var color = ZColor.White()
    let startValue: Float
    var value: Float = 0

    init(value:Float, parent:ZContainerView, target:ZBallSwitch) {
        self.value = value
        self.startValue = value
        super.init(name:"ballselector")
        parent.Add(self, align:.None)
        let r = parent.GetViewsRectInMyCoordinates(target)
        frame = ZRect(size:ZSize(rfull * 2, rfull * 2)).Centered(r.Center).GetCGRect() // can't use Rect for some reason
        rout = rfull - marg
    }
    
    required init?(coder aDecoder:NSCoder) { fatalError("init(coder:) has not been implemented") }

    func SetDistance(_ distance:Double) -> Float { // set x-distance, get current value back
        let v = (distance - rin) / (rout - rin)
        if v > 2 {
           return -startValue
        } else {
            value = Float(min(max(0, v), 1.0))
            value = Float(Int(value * 20)) / 20 // need int conversion first
            Expose()
        }
        return value
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let path = ZPath()
        let c = rect.Center
        
        rout = rect.size.w / 2 - 15
        canvas.SetColor(ZColor.Black())
        path.ArcDegFromToFromCenter(c, radius:rect.size.w / 2)
        canvas.FillPath(path)
        path.Empty()
        canvas.SetColor(color)
        
        path.ArcDegFromToFromCenter(c, radius:rect.size.w / 2 - 3)
        canvas.StrokePath(path, width:6)
        path.Empty()

        path.ArcDegFromToFromCenter(c, radius:rin)
        path.ArcDegFromToFromCenter(c, radius:rin + (rout - rin) * Double(value))
        canvas.FillPath(path, eofill:true)
        
        var text = ZText()
        text.color = color
        text.text = "\(Int(value * 100))%"
        text.alignment = .Center
        text.font = ZFont.appFont
        text.rect = rect
        text.Draw(canvas)
    }
    
    override func HandleTouched(_ sender:ZView, state:ZGestureState, pos:ZPos, inside:Bool) -> Bool {
        switch state {
        case .began:
            return super.HandleTouched(sender, state:state, pos:pos, inside:inside)
            
        case .changed, .ended:
            print("touch:", pos)
            return true
            
        default:
            return false
        }
    }
}


