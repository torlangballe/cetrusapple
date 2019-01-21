//  ZCustomView.swift
//
//  Created by Tor Langballe on /21/10/15.
//

import UIKit

protocol ZCustomViewDelegate {
    func DrawInRect(_ rect: ZRect, canvas: ZCanvas)
}

open class ZCustomView: UIControl, ZView, ZControl, UIGestureRecognizerDelegate {
    public var objectName = ""
    var minSize = ZSize(0, 0)
    var drawHandler:((_ rect: ZRect, _ canvas: ZCanvas, _ view:ZCustomView)->Void)? = nil
    var foregroundColor = ZColor.Black()
    var canFocus = false
    var touchInfo = ZTouchInfo()

    var IsFocused: Bool {
        return isFocused
    }
    
    var HandlePressedInPosFunc: ((_ pos: ZPos)->Void)? {
        get {
            return touchInfo.handlePressedInPosFunc
        }
        set {
            touchInfo.handlePressedInPosFunc = newValue
            canFocus = true
            isUserInteractionEnabled = true
            isAccessibilityElement = true
            accessibilityTraits = UIAccessibilityTraits(rawValue: accessibilityTraits.rawValue | UIAccessibilityTraits.button.rawValue)
            if ZIsTVBox() {
                AddGestureTo(self, type:ZGestureType.tap)
            }
        }
    }
    
    private var handleValueChangedFunc: (()->Void)? = nil
    
    weak var valueTarget: ZCustomView? = nil
    var timers = [ZTimerBase]()
    
    func SetHandleValueChangedFunc(_ handler:@escaping ()->Void) {
        handleValueChangedFunc = handler
        self.AddTarget(self, forEventType:.valueChanged)
    }
    
    public func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
        switch forEventType {
//        case .pressed:
//            touchInfo.tapTarget = t
        case .valueChanged:
            valueTarget = t
        }
        isUserInteractionEnabled = true
    }
    
    public var Usable: Bool {
        get { return isEnabled }
        set {
            isEnabled = newValue
          accessibilityTraits =  isEnabled ? UIAccessibilityTraits.none : UIAccessibilityTraits.notEnabled
            Expose()
        }
    }
    
    public func View() -> UIView {
        return self
    }
    
    public func Control() -> UIControl {
        return self
    }
    
    init(name: String = "customview") {
        objectName = name
        minSize = ZSize(10, 10)
        foregroundColor = ZColor(color: ZColor.Black().color)
        super.init(frame: ZRect(size:minSize).GetCGRect())
        isOpaque = false
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
        Expose()
    }
    
    // #swift-only:
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:)") }
    // #end
    
    public func CalculateSize(_ total: ZSize) -> ZSize {
        return minSize
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CalculateSize(ZSize(size)).GetCGSize()
    }
    
    open override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
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
          UIAccessibility.post(notification: UIAccessibility.Notification.pageScrolled, argument: message)
        }
        return handled
    }
    
    func HandleAcessibilityScroll(_ direction:ZAlignment) -> (Bool, String) {
        return (false, "")
    }
    
    open override var canBecomeFocused: Bool {
        return canFocus
    }
    
    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        Expose()
//        if context.nextFocusedView == self {
//            coordinator.addCoordinatedAnimations({ () -> Void in
//                self.layer.backgroundColor = UIColor.blue.withAlphaComponent(0.2).cgColor
//            }, completion: nil)
//
//        } else if context.previouslyFocusedView == self {
//            coordinator.addCoordinatedAnimations({ () -> Void in
//                self.layer.backgroundColor = UIColor.clear.cgColor
//            }, completion: nil)
//        }
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoBeginTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoEndTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoContinueTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoTrackingCanceled(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        drawHandler?(rect, canvas, self)
    }
    
    override open func draw(_ rect: CGRect) {
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
    
//    @objc func handlePressed(_ sender:UIView?) { // this is for special ZControl views to send press to parent
//        touchInfo.doPressed?(LocalRect.Center)
//    }
    
    @objc func handleValueChanged(_ sender:UIView?) {
        if handleValueChangedFunc != nil {
            handleValueChangedFunc!()
        } else {
            HandleValueChanged(sender as! ZView)
        }
    }
    
//    func HandlePressed(_ sender: ZView, pos:ZPos) {
//    }

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
    override open func layoutSubviews() {
        super.layoutSubviews()
        HandleAfterLayout()
    }
    
    open func HandleBeforeLayout() {
        Expose()
    }
    
    open func HandleAfterLayout() {
        Expose()
    }
    
    open func HandleTransitionedToSize() {
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
    
    open func HandleOpening() {
        Focus()
    }
    
    open func HandleRevealedAgain() {
        Focus()
    }
    
    func RefreshAccessibility() {
        //!
    }
    
    func Activate(_ activate:Bool) { // like being activated/deactivated for first time
    }
    
    override open var canBecomeFirstResponder : Bool {
        return canFocus
    }
    
  override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
//        if motion == .motionShake {
//            mainZApp?.HandleShake()
//        }
    }
    
    func AddGestureTo(_ view:ZView, type:ZGestureType, taps:Int = 1, touches:Int = 1, duration:Double = 0.8, movement:Double = 10, dir:ZAlignment = .None) {
        view.View().isUserInteractionEnabled = true
        
        switch type {
        case .tap:
            let gtap = UITapGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            gtap.numberOfTapsRequired = taps
            #if os(iOS)
            gtap.numberOfTouchesRequired = touches
            #endif
            #if os(tvOS)
            gtap.allowedPressTypes = [NSNumber(value:UIPress.PressType.select.rawValue)] // only this for now
            #endif
            gtap.cancelsTouchesInView = true
            addGesture(gtap, view:view, handler:self)
            view.View().addGestureRecognizer(gtap)
//            for g in view.View().gestureRecognizers ?? [] {
//                if let tg = g as? UITapGestureRecognizer, tg != gtap {
//                    tg.require(toFail:gtap)
//                }
//            }
//            if view.View().superview != nil {
//                for g in view.View().superview?.gestureRecognizers ?? [] {
//                    if let tg = g as? UITapGestureRecognizer, tg != gtap {
//                        tg.require(toFail:gtap)
//                    }
//                }
//            }
            
        case .longpress:
            let glong = UILongPressGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            glong.numberOfTapsRequired = taps - 1
            #if os(iOS)
            glong.numberOfTouchesRequired = touches
            #endif
            glong.allowableMovement = CGFloat(movement)
            glong.minimumPressDuration = CFTimeInterval(duration)
            addGesture(glong, view:view, handler:self)
            view.View().addGestureRecognizer(glong)

        case .pan:
            let gpan = UIPanGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            #if os(iOS)
            gpan.minimumNumberOfTouches = touches
            #endif
            addGesture(gpan, view:view, handler:self)
            view.View().addGestureRecognizer(gpan)

        case .pinch:
            #if os(iOS)
          let gpinch = UIPinchGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            addGesture(gpinch, view:view, handler:self)
            view.View().addGestureRecognizer(gpinch)
            #endif
            
        case .swipe:
            let gswipe = UISwipeGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            #if os(iOS)
            gswipe.numberOfTouchesRequired = touches
            #endif
            switch dir {
            case ZAlignment.Left  : gswipe.direction = UISwipeGestureRecognizer.Direction.left
            case ZAlignment.Right : gswipe.direction = UISwipeGestureRecognizer.Direction.right
            case ZAlignment.Top   : gswipe.direction = UISwipeGestureRecognizer.Direction.up
            case ZAlignment.Bottom: gswipe.direction = UISwipeGestureRecognizer.Direction.down
            default:
                return
            }
            addGesture(gswipe, view:view, handler:self)
            view.View().addGestureRecognizer(gswipe)
            
        case .rotation:
            #if os(iOS)
            let grot = UIRotationGestureRecognizer(target:self, action:#selector(self.handleGesture(_:)))
            addGesture(grot, view:view, handler:self)
            view.View().addGestureRecognizer(grot)
            #endif
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
        case UIGestureRecognizer.State.possible: state = .possible
        case UIGestureRecognizer.State.began: state = .began
        case UIGestureRecognizer.State.changed: state = .changed
        case UIGestureRecognizer.State.ended: state = .ended
        case UIGestureRecognizer.State.cancelled: state = .canceled
        case UIGestureRecognizer.State.failed: state = .failed
        }
        #if os(iOS)
        if state == .began && UIMenuController.shared.isMenuVisible {
            g.isEnabled = false // hides popup text menu?
            g.isEnabled = true
            UIMenuController.shared.isMenuVisible = false
        }
        #endif
        if let gtap = g as? UITapGestureRecognizer {
            type = .tap
            taps = gtap.numberOfTapsRequired
            #if os(iOS)
            touches = gtap.numberOfTouchesRequired
            #endif
            #if os(tvOS)
            if let vc = g.view as? ZCustomView {
                vc.touchInfo.handlePressedInPosFunc?(ZPos(0, 0))
            }
            #endif
        } else if let glong = g as? UILongPressGestureRecognizer {
            type = .longpress
            taps = glong.numberOfTapsRequired
            #if os(iOS)
            touches = glong.numberOfTouchesRequired
            #endif
        } else if let gpan = g as? UIPanGestureRecognizer {
            type = .pan
            #if os(iOS)
            touches = gpan.maximumNumberOfTouches
            #endif
            delta = ZPos(gpan.translation(in: g.view))
            velocity = ZPos(gpan.velocity(in: g.view))
        }
        #if os(iOS)
        if let gpinch = g as? UIPinchGestureRecognizer {
            type = .pinch
            gvalue = Float(gpinch.scale)
            velocity.x = Double(gpinch.velocity)
            velocity.y = velocity.x
        } else if let grot = g as? UIRotationGestureRecognizer {
            type = .rotation
            gvalue = Float(grot.rotation)
            velocity.x = Double(grot.velocity)
            velocity.y = velocity.x
        }
        #endif
        if let gswipe = g as? UISwipeGestureRecognizer {
            type = .swipe
            #if os(iOS)
            touches = gswipe.numberOfTouchesRequired
            #endif
            switch gswipe.direction {
            case UISwipeGestureRecognizer.Direction.right:
                delta = ZPos(1, 0)
                name = "swiperight"
                align = ZAlignment.Right
            case UISwipeGestureRecognizer.Direction.left:
                delta = ZPos(-1, 0)
                name = "swipeleft"
                align = ZAlignment.Left
            case UISwipeGestureRecognizer.Direction.up:
                delta = ZPos(0, -1)
                name = "swipeup"
                align = ZAlignment.Top
            case UISwipeGestureRecognizer.Direction.down:
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

    private func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private func addGesture(_ g: UIGestureRecognizer, view:ZView, handler:ZCustomView) {
    view.View().isUserInteractionEnabled = true
//    g.delaysTouchesEnded = true
    g.delegate = handler
}

func zConvertViewSizeThatFitstToZSize(_ view:UIView, sizeIn:ZSize) -> ZSize {
    return ZSize(view.sizeThatFits(sizeIn.GetCGSize()))
}

func zSetViewFrame(_ view:UIView, frame:ZRect, layout:Bool = false) { // layout only used on android
    view.frame = frame.GetCGRect()
}

func zRemoveViewFromSuper(_ view:UIView) {
    view.removeFromSuperview()
}

