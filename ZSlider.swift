//
//  ZSlider.swift
//  Zed
//
//  Created by Tor Langballe on /24/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZSlider: UISlider, ZView, ZControl {
    var objectName: String = "ZSlider"
    var vertical: Bool = false
    var minLength: Int = 140
    var ticks = [String:Float]()
    func View() -> UIView { return self }
    func Control() -> UIControl { return self }
    var ValueString: ((_ val:Float) -> String)
    var handleValueChanged: (() -> Void)? = nil

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return calculateSize(vertical, minLength:minLength, hasTicks:ticks.count > 0)
    }
    
    init(vertical:Bool = false, minLength:Int = 100) {
        self.vertical = vertical
        self.minLength = minLength
        ValueString = { (val) in
            return "\(val)"
        }
        super.init(frame:CGRect(origin:CGPoint(), size:calculateSize(vertical, minLength:minLength, hasTicks:ticks.count > 0)))
        if !vertical {
            contentMode = ZViewContentMode.bottom
        }
        if vertical {
            transform = CGAffineTransform(rotationAngle: CGFloat(-ZMath.PI))
        }
        addTarget(self, action:#selector(ZSlider.valueChanged(_:)), for:UIControlEvents.valueChanged)
    }
    
    @objc func valueChanged(_ sender:UISlider) {
        setNeedsDisplay()
        handleValueChanged?()
    }
    
    func SetValue(_ value:Float, animationDuration:Float=0.0) {
        if animationDuration != 0.0 {
            UIView.animate(withDuration: TimeInterval(animationDuration), animations: { [weak self] () in
                self?.setValue(value, animated:true)
            }) 
        } else {
            self.value = value
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with:event)
        for (_, v) in ticks {
            let delta = (maximumValue - minimumValue) / 10
            if abs(v - value) < delta {
                setValue(v, animated:true)
                break
            }
        }
    }
    
    override var accessibilityValue: String? {
        get { return ValueString(value) }
        set { }
    }

    override func draw(_ rect:CGRect) {
        super.draw(rect)
        if ticks.count > 0 {
            if vertical {
            } else {
                var f = frame
                f.origin.x = 0
                let r = ZRect(trackRect(forBounds: f)).Expanded(ZSize(-16, 0))
                for (s, v) in ticks {
                    let path = ZPath()
                    let canvas = ZCanvas(context: UIGraphicsGetCurrentContext()!)
                    let x = (v - minimumValue) / (maximumValue - minimumValue)
                    let pos = ZPos(r.pos.x + Double(x) * r.size.w, r.Max.y)
                    var text = ZText()
                    //                    path.ArcDegFromToFromCenter(pos, radius:5, degStart:0, degEnd:360)
                    //                    canvas.SetColor(v > value ? ZColor(white:0.72157) : ZColor(r:0, g:0.47843, b:1))
                    canvas.SetColor(ZColor(white:0.72157))
                    path.MoveTo(pos + ZPos(0, -2))
                    path.LineTo(pos + ZPos(0, -8))
                    canvas.StrokePath(path, width:2)
                    text.text = s
                    text.alignment = ZAlignment.HorCenter | ZAlignment.Top
                    text.font = ZFont(name:"AvenirNextCondensed-Regular", size:13)!
                    text.rect = ZRect(size:ZSize(50, 24)).Centered(pos + ZPos(0, -16))
                    text.color = ZColor(white:1, a:0.5)
                    text.Draw(canvas)
                }
            }
        }
    }
    
    func PopInView(parent:ZContainerView, target:ZView, popInRectMarg:ZRect, done:@escaping (_ result:Float)->Void) {
        var w = ZStackView(name:"sliderpop")
        w.vertical = vertical
        w.space = 4
        w.margin = ZRect(16, 16, -16, -16)
        w.SetBackgroundColor(ZColor(white:0.3))
        w.SetCornerRadius(16)
        
        w.Add(self, align:.Top | .HorCenter | .VertExpand | .NonProp)
        w.Show(false)
        w.alpha = 0
        
        let close = ZImageView(namedImage:"cross.small.png")
        close.HandlePressedInPosFunc = { (pos) in
            parent.RemoveChild(w)
            done(self.value)
        }
        
        w.Add(close, align:.Bottom | .HorCenter)
        
        parent.Add(w, align:.None)
        
        let s = w.CalculateSize(ZSize(320, 320))
        var r = ZRect(size:s).Centered(parent.GetViewsRectInMyCoordinates(target).Center)
        r.MoveInto(parent.Rect)
        r += popInRectMarg
        w.Rect = r
        w.ArrangeChildren()
        w.Show(true)
        
        let oldHandle = parent.HandlePressedInPosFunc
        
        AddTarget(parent, forEventType:.pressed)
        parent.HandlePressedInPosFunc = { (pos) in
            done(self.value)
            parent.RemoveChild(w)
            parent.HandlePressedInPosFunc = oldHandle
        }
        ZAnimation.Do(duration:0.5, animations: {
            w.alpha = 1
        })
    }
}

func calculateSize(_ vertical: Bool, minLength:Int, hasTicks:Bool) -> CGSize {
    if vertical {
        return CGSize(width:43, height:minLength)
    }
    var h = 43;
    if hasTicks {
        h += 4
    }
    return CGSize(width:minLength, height:h)
}


