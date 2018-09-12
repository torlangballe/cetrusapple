//  ZCustomView.swift
//  Zed
//
//  Created by Tor Langballe on /21/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

protocol ZCustomViewDelegate {
    func DrawInRect(_ rect: ZRect, canvas: ZCanvas)
}

class ZCustomView: UIControl, ZView, UIGestureRecognizerDelegate, ZTimerOwner {
    var objectName = ""
    var minSize = ZSize(0, 0)
    var drawHandler:((_ rect: ZRect, _ canvas: ZCanvas, _ view:ZCustomView)->Void)? = nil
    var foregroundColor = ZColor.Black()
    var touchDownRepeatSecs = 0.0
    let touchDownRepeatTimer = ZRepeater()
    var canFocus = false
    var HandlePressedInPosFunc: ((_ pos:ZPos)->Void)? = nil
    
    private var handleValueChangedFunc: (()->Void)? = nil
    
    weak var tapTarget: ZCustomView? = nil
    weak var valueTarget: ZCustomView? = nil
    var timers = [ZTimerBase]()
    
    func SetHandleValueChangedFunc(_ handler:@escaping ()->Void) {
        handleValueChangedFunc = handler
        self.AddTarget(self, forEventType:.valueChanged)
    }
    
    func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
        switch forEventType {
        case .pressed:
            tapTarget = t
        case .valueChanged:
            valueTarget = t
        }
        isUserInteractionEnabled = true
    }
    
    var Usable: Bool {
        get { return isEnabled }
        set {
            isEnabled = newValue
            accessibilityTraits =  isEnabled ? UIAccessibilityTraitNone : UIAccessibilityTraitNotEnabled
            Expose()
        }
    }
    
    func View() -> UIView {
        return self
    }
    
    func Control() -> UIControl {
        return self
    }
    
    init(name: String = "customview") {
        objectName = name
        minSize = ZSize(10, 10)
        foregroundColor = ZColor(color: ZColor.Black().color)
        super.init(frame: ZRect(size:minSize).GetCGRect())
        isOpaque = false
        backgroundColor = UIColor.clear
        Expose()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:)") }
    
    func CalculateSize(_ total: ZSize) -> ZSize {
        return minSize
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CalculateSize(ZSize(size)).GetCGSize()
    }
    
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var a: ZAlignment
        switch direction {
        case .down:
            a = .Top
            
        case .up:
            a = .Bottom
            
        case .left:
            a = .Left
            
        case .right:
            a = .Right
            
        default:
            return false
        }
        let (handled, message) = HandleAcessibilityScroll(a)
        if handled && !message.isEmpty {
            UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, message)
        }
        return handled
    }
    
    func HandleAcessibilityScroll(_ direction:ZAlignment) -> (Bool, String) {
        return (false, "")
    }
    
    fileprivate func doPressed(_ touch: UITouch?) {
        var pos = LocalRect.Center
        if touch != nil {
            pos = ZPos(touch!.location(in: self))
        }
        if HandlePressedInPosFunc != nil {
            HandlePressedInPosFunc!(pos)
        } else {
            tapTarget!.HandlePressed(self, pos:pos)
        }
    }
    
    internal override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if tapTarget != nil || HandlePressedInPosFunc != nil {
            isHighlighted = true
            Expose()
            tapTarget?.HandleTouched(self, state:.began, pos:ZPos(touch.location(in: self)), inside:true)
            if touchDownRepeatSecs != 0 {
                touchDownRepeatTimer.Set(touchDownRepeatSecs, owner:self) { [weak self] () in
                    self?.doPressed(touch)
                    return true
                }
            }
        }
        return super.beginTracking(touch, with:event)
    }
    
    internal override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if tapTarget != nil || HandlePressedInPosFunc != nil {
            let pos = ZPos(touch.location(in: self))
            let inside = Rect.Contains(pos)
            tapTarget?.HandleTouched(self, state:.changed, pos:pos, inside:inside)
            touchDownRepeatTimer.Stop()
        }
        return super.continueTracking(touch, with:event)
    }
    
    internal override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if !Thread.isMainThread {
            return
        }
        isHighlighted = false
        if tapTarget != nil || HandlePressedInPosFunc != nil {
            let pos = ZPos((touch?.location(in: self))!)
            let inside = LocalRect.Contains(pos)
            if tapTarget == nil || !tapTarget!.HandleTouched(self, state:.ended, pos:pos, inside:inside) {
                PerformAfterDelay(0.05) { [weak self] () in
                    self?.Expose()
                }
                if inside {
                    doPressed(touch!)
                }
                super.endTracking(touch, with:event)
            }
            touchDownRepeatTimer.Stop()
        }
    }
    
    internal override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        isHighlighted = false
        Expose()
        touchDownRepeatTimer.Stop()
    }
    
    func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        drawHandler?(rect, canvas, self)
    }
    
    override func draw(_ rect: CGRect) {
        DrawInRect(ZRect(rect), canvas: ZCanvas(context: UIGraphicsGetCurrentContext()!))
    }
    
    func SetFGColor(_ color: ZColor) {
        foregroundColor = color
        Expose()
    }
    
    func GetPosFromMe(_ pos:ZPos, inView:UIView) -> ZPos {
        let cgpos = self.convert(pos.GetCGPoint(), to:inView)
        return ZPos(cgpos)
    }

    func GetPosToMe(_ pos:ZPos, inView:UIView) -> ZPos {
        let cgpos = inView.convert(pos.GetCGPoint(), to:self)
        return ZPos(cgpos)
    }

    func GetViewsRectInMyCoordinates(_ view: ZView) -> ZRect {
        return ZRect(convert(CGRect(origin:CGPoint(), size:view.View().frame.size), from:view.View()))
    }
    
    func getStateColor(_ col: ZColor) -> ZColor {
        var vcol = col
        if isHighlighted {
            let g = col.GrayScale
            if g < 0.5 {
                vcol = col.Mix(ZColor.White(), amount:0.5)
            } else {
                vcol = col.Mix(ZColor.Black(), amount:0.5)
            }
        }
        if !isEnabled {
            vcol  = vcol.OpacityChanged(0.3)
        }
        return vcol
    }
    
    func HandleGestureType(_ type:ZGestureType, view:ZView, pos:ZPos, delta:ZPos, state:ZGestureState, taps:Int, touches:Int, dir:ZAlignment, velocity:ZPos, gvalue:Float, name:String) ->Bool {
        return true
    }
    
    @objc func handlePressed(_ sender:UIView?) { // this is for special ZControl views to send press to parent
        doPressed(nil)
    }
    
    @objc func handleValueChanged(_ sender:UIView?) {
        if handleValueChangedFunc != nil {
            handleValueChangedFunc!()
        } else {
            HandleValueChanged(sender as! ZView)
        }
    }
    
    func HandlePressed(_ sender: ZView, pos:ZPos) {
    }

    @discardableResult func HandleTouched(_ sender:ZView, state:ZGestureState, pos:ZPos, inside:Bool) -> Bool {
        return false
    }
    
    func HandleValueChanged(_ sender:ZView) {
    }

    func HandleValueChangedEnded(_ sender:ZView) {
    }
/*
     func AddTimer(timerBase:ZTimerBase) {
     timers.append(timerBase)
     }
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        HandleAfterLayout()
    }
    
    func HandleBeforeLayout() {
        Expose()
    }
    
    func HandleAfterLayout() {
        Expose()
    }
    
    func HandleTransitionedToSize() {
    }
    
    func HandleClosing() {
        for t in timers {
            t.Stop()
        }
        timers.removeAll()
        if let cv = self as? ZContainerView {
            cv.RangeChildren() { (view) in
                if let ccv = view as? ZCustomView {
                    ccv.HandleClosing()
                } else if let ssv = view as? ZScrollView {
                    ssv.child?.HandleClosing()
                }
                if let tv = view as? ZTableView {
                    tv.scrolling = false
                }
                return true
            }
        }
    }
    
    func HandleOpening() {
        Focus()
    }
    
    func HandleRevealedAgain() {
        Focus()
    }
    
    func RefreshAccessibility() {
        //!
    }
    
    func Activate(_ activate:Bool) { // like being activated/deactivated for first time
    }
    
    override var canBecomeFirstResponder : Bool {
        return canFocus
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            mainZApp?.HandleShake()
        }
    }
    
    func AddGestureTo(_ view:ZView, type:ZGestureType, taps:Int = 1, touches:Int = 1, duration:Float = 0.8, movement:Float = 10, dir:ZAlignment = .None) {
        view.View().isUserInteractionEnabled = true
        
        switch type {
        case .tap:
            let gtap = UITapGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            gtap.numberOfTapsRequired = taps
            gtap.numberOfTouchesRequired = touches
            gtap.cancelsTouchesInView = true
            addGesture(gtap, view:view, handler:self)
            view.View().addGestureRecognizer(gtap)
            for g in view.View().gestureRecognizers ?? [] {
                if let tg = g as? UITapGestureRecognizer, tg != gtap {
                    tg.require(toFail:gtap)
                }
            }
            if view.View().superview != nil {
                for g in view.View().superview?.gestureRecognizers ?? [] {
                    if let tg = g as? UITapGestureRecognizer, tg != gtap {
                        tg.require(toFail:gtap)
                    }
                }
            }
            
        case .longpress:
            let glong = UILongPressGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            glong.numberOfTapsRequired = taps - 1
            glong.numberOfTouchesRequired = touches
            glong.allowableMovement = CGFloat(movement)
            glong.minimumPressDuration = CFTimeInterval(duration)
            addGesture(glong, view:view, handler:self)
            view.View().addGestureRecognizer(glong)

        case .pan:
            let gpan = UIPanGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            gpan.minimumNumberOfTouches = touches
            addGesture(gpan, view:view, handler:self)
            view.View().addGestureRecognizer(gpan)

        case .pinch:
          let gpinch = UIPinchGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            addGesture(gpinch, view:view, handler:self)
            view.View().addGestureRecognizer(gpinch)
            
        case .swipe:
            let gswipe = UISwipeGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            gswipe.numberOfTouchesRequired = touches
            switch dir {
            case ZAlignment.Left  : gswipe.direction = UISwipeGestureRecognizerDirection.left
            case ZAlignment.Right : gswipe.direction = UISwipeGestureRecognizerDirection.right
            case ZAlignment.Top   : gswipe.direction = UISwipeGestureRecognizerDirection.up
            case ZAlignment.Bottom: gswipe.direction = UISwipeGestureRecognizerDirection.down
            default:
                return
            }
            addGesture(gswipe, view:view, handler:self)
            view.View().addGestureRecognizer(gswipe)
            
        case .rotation:
            let grot = UIRotationGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            addGesture(grot, view:view, handler:self)
            view.View().addGestureRecognizer(grot)
        }
    }
    
    @objc func handleGesture(_ g: UIGestureRecognizer) {
        //    widget->StopTimer(0, ZEV_DELAYEDTOUCH_UP)
        let pos = ZPos(g.location(in: g.view))
        var delta = ZPos()
        var state: ZGestureState
        var type: ZGestureType = .tap
        var taps:Int = 1
        var touches:Int = 1
        var velocity = ZPos()
        var gvalue:Float = 0
        var name = ""
        var align = ZAlignment.None
        
        switch g.state {
        case UIGestureRecognizerState.possible: state = .possible
        case UIGestureRecognizerState.began: state = .began
        case UIGestureRecognizerState.changed: state = .changed
        case UIGestureRecognizerState.ended: state = .ended
        case UIGestureRecognizerState.cancelled: state = .canceled
        case UIGestureRecognizerState.failed: state = .failed
        }
        if state == .began && UIMenuController.shared.isMenuVisible {
            g.isEnabled = false // hides popup text menu?
            g.isEnabled = true
            UIMenuController.shared.isMenuVisible = false
        } else  if let gtap = g as? UITapGestureRecognizer {
            type = .tap
            taps = gtap.numberOfTapsRequired
            touches = gtap.numberOfTouchesRequired
        } else if let glong = g as? UILongPressGestureRecognizer {
            type = .longpress
            taps = glong.numberOfTapsRequired
            touches = glong.numberOfTouchesRequired
        } else if let gpan = g as? UIPanGestureRecognizer {
            type = .pan
            touches = gpan.maximumNumberOfTouches
            delta = ZPos(gpan.translation(in: g.view))
            velocity = ZPos(gpan.velocity(in: g.view))
        } else if let gpinch = g as? UIPinchGestureRecognizer {
            type = .pinch
            gvalue = Float(gpinch.scale)
            velocity.x = Double(gpinch.velocity)
            velocity.y = velocity.x
        } else if let grot = g as? UIRotationGestureRecognizer {
            type = .rotation
            gvalue = Float(grot.rotation)
            velocity.x = Double(grot.velocity)
            velocity.y = velocity.x
        } else if let gswipe = g as? UISwipeGestureRecognizer {
            type = .swipe
            touches = gswipe.numberOfTouchesRequired
            switch gswipe.direction {
            case UISwipeGestureRecognizerDirection.right:
                delta = ZPos(1, 0)
                name = "swiperight"
                align = ZAlignment.Right
            case UISwipeGestureRecognizerDirection.left:
                delta = ZPos(-1, 0)
                name = "swipeleft"
                align = ZAlignment.Left
            case UISwipeGestureRecognizerDirection.up:
                delta = ZPos(0, -1)
                name = "swipeup"
                align = ZAlignment.Top
            case UISwipeGestureRecognizerDirection.down:
                delta = ZPos(0, 1)
                name = "swipedown"
                align = ZAlignment.Bottom
            default:
                return
            }
        }
        if !HandleGestureType(type, view:g.view as! ZView, pos:pos, delta:delta, state:state, taps:taps, touches:touches, dir:align, velocity:velocity, gvalue:gvalue, name:name) {
            g.isEnabled = false
            g.isEnabled = true
        }
    }
    
    func Rotate(degrees:Double) {
        let r = ZMath.DegToRad(degrees)
        self.transform = CGAffineTransform(rotationAngle:CGFloat(r))
    }
    
    @objc(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:) func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private func addGesture(_ g: UIGestureRecognizer, view:ZView, handler:ZCustomView) {
    view.View().isUserInteractionEnabled = true
    g.delaysTouchesEnded = true
    g.delegate = handler
}

func zConvertViewSizeThatFitstToZSize(view:UIView, sizeIn:ZSize) -> ZSize {
    return ZSize(view.sizeThatFits(sizeIn.GetCGSize()))
}

func zSetViewFrame(_ view:UIView, frame:ZRect) {
    view.frame = frame.GetCGRect()
}

func zRemoveViewFromSuper(_ view:UIView) {
    view.removeFromSuperview()
}

