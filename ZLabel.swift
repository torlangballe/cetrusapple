//
//  ZLabel.swift
//  Zed
//
//  Created by Tor Langballe on /2/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZLabel: UILabel, ZView {
    weak var tapTarget: ZCustomView? = nil
    var objectName: String = "ZLabel"
    var minWidth:Double = 0
    var maxWidth:Double = 0
    var maxHeight:Double? = nil
    var margin = ZRect()
    private var handlePressedInPosFunc: ((_ pos:ZPos)->Void)? = nil
    var Color: ZColor {
        get { return ZColor(color:textColor) }
        set { textColor = newValue.color }
    }
    
    init(text:String="", minWidth:Double=0, maxWidth:Double=0, lines:Int=1, font:ZFont?=nil, align:ZAlignment = .Left, color:ZColor = ZColor.White()) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        super.init(frame:CGRect(x:0, y:0, width:10, height:10))
        self.font = font
        self.numberOfLines = lines
        self.text = text
        self.SetAlignment(align)
        self.Color = color
    }

    var HandlePressedInPosFunc: ((_ pos:ZPos)->Void)? {
        set {
            handlePressedInPosFunc = newValue
            isUserInteractionEnabled = true
            isAccessibilityElement = true
            accessibilityTraits |= UIAccessibilityTraitButton
        }
        get {
            return handlePressedInPosFunc;
        }
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top:CGFloat(margin.Min.y), left:CGFloat(margin.Min.x), bottom:CGFloat(-margin.Max.y), right:CGFloat(-margin.Max.x))
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
        if handlePressedInPosFunc != nil { // we hack this in here...
            isUserInteractionEnabled = true
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var box = ZSize()
        if maxWidth != 0 {
            box.w = maxWidth
        }
        box.h = 99999;
        var gs = super.sizeThatFits(box.GetCGSize())
        if minWidth != 0.0 {
            maximize(&gs.width, CGFloat(minWidth))
        }
        if self.numberOfLines > 1 {
            maximize(&gs.height, font.lineHeight * CGFloat(self.numberOfLines) * 1.2)
        }
        maximize(&gs.height, font.pointSize * 1.2)
        gs.width -= CGFloat(margin.size.w) // margin is typically 10, -10, so must subtract
        gs.height -= CGFloat(margin.size.h)
        if maxWidth != 0.0 {
            minimize(&gs.width, CGFloat(maxWidth))
        }
        if maxHeight != nil {
            minimize(&gs.height, CGFloat(maxHeight!))
        }
        return gs
    }

    func View() -> UIView {
        return self
    }
    
    func SetAlignment(_ a: ZAlignment) {
        textAlignment = ZText.GetTextAdjustment(a)
    }
    
    func FadeTransition(_ duration:Float) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = CFTimeInterval(duration)
        self.layer.add(animation, forKey: kCATransitionFade)
    }
    
    func SetText(_ newText:String, animationDuration:Float=0) {
        if self.text != newText {
            if animationDuration != 0.0 {
                UIView.transition(with: self, duration:TimeInterval(animationDuration), options:UIViewAnimationOptions.transitionCrossDissolve, animations:{
                    self.text = newText
                }, completion:nil)
            } else {
                self.text = newText
            }
        }
    }
    
    func SetLinebreakMode(_ mode:ZText.WrapType) {
        self.lineBreakMode = ZText.GetNativeWrapMode(mode)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            if tapTarget != nil {
                let pos = ZPos(touches.first!.location(in: self))
                tapTarget?.HandleTouched(self, state:.began, pos:pos, inside:true)
            }
            isHighlighted = true
            Expose()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            if tapTarget != nil {
                let pos = ZPos(touches.first!.location(in: self))
                let inside = self.Rect.Contains(pos)
                tapTarget?.HandleTouched(self, state:.ended, pos:pos, inside:inside)
            }
            isHighlighted = false
            self.PerformAfterDelay(0.05) { () in
                self.Expose()
            }
            let pos = ZPos(touches.first!.location(in: self))
            if handlePressedInPosFunc != nil {
                handlePressedInPosFunc!(pos)
            } else if tapTarget != nil {
                tapTarget?.HandlePressed(self, pos:pos)
            }
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            if tapTarget != nil {
                tapTarget?.HandleTouched(self, state:.canceled, pos:ZPos(), inside:false)
            }
            isHighlighted = false
            Expose()
        }
    }
    
    func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
        tapTarget = t
        assert(forEventType == .pressed)
        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

