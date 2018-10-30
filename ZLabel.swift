//
//  ZLabel.swift
//
//  Created by Tor Langballe on /2/11/15.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

class ZLabel: UILabel, ZView {
    weak var tapTarget: ZCustomView? = nil
    var objectName: String = "ZLabel"
    var minWidth:Double = 0
    var maxWidth:Double = 0
    var maxHeight:Double? = nil
    var margin = ZRect()
    var touchInfo = ZTouchInfo()
    
    var Color: ZColor {
        get { return ZColor(color:textColor) }
        set { textColor = newValue.color }
    }

    init(text:String="", minWidth:Double=0, maxWidth:Double=0, lines:Int=1, font:ZFont? = nil, align:ZAlignment = .Left, color:ZColor = ZColor.White()) {
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
            touchInfo.handlePressedInPosFunc = newValue
            isUserInteractionEnabled = true
            isAccessibilityElement = true
            accessibilityTraits |= UIAccessibilityTraitButton
        }
        get {
            return touchInfo.handlePressedInPosFunc;
        }
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top:CGFloat(margin.Min.y), left:CGFloat(margin.Min.x), bottom:CGFloat(-margin.Max.y), right:CGFloat(-margin.Max.x))
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
        if touchInfo.handlePressedInPosFunc != nil { // we hack this in here...
            isUserInteractionEnabled = true
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var box = ZSize()
        if maxWidth != 0 {
            box.w = maxWidth
        }
        box.w = max(box.w, Double(size.width))
        if self.numberOfLines > 1 {
            box = ZSize(Double(size.width), Double(font.lineHeight) * Double(self.numberOfLines) * 1.1)
        } else {
            box.h = 99999;
        }
        var gs = super.sizeThatFits(box.GetCGSize())
        if minWidth != 0.0 {
            gs.width = max(gs.width, CGFloat(minWidth))
        }
        gs.height = max(gs.height, font.pointSize * 1.2)
        gs.width -= CGFloat(margin.size.w) // margin is typically 10, -10, so must subtract
        gs.height -= CGFloat(margin.size.h)
        if maxWidth != 0.0 {
            gs.width = min(gs.width, CGFloat(maxWidth))
        }
        if maxHeight != nil {
            gs.height = min(gs.height, CGFloat(maxHeight!))
        }
        return gs
    }

    func View() -> UIView {
        return self
    }
    
    func SetAlignment(_ a: ZAlignment) {
        textAlignment = ZTextDraw.GetTextAdjustment(a)
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
    
    func SetLinebreakMode(_ mode:ZTextWrapType) {
        self.lineBreakMode = ZTextDraw.GetNativeWrapMode(mode)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoBeginTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoEndTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoContinueTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoTrackingCanceled(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
        tapTarget = t
        assert(forEventType == .pressed)
        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

