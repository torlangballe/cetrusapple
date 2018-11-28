//
//  ZViewIOS.swift
//  capsule.fm
//
//  Created by Tor Langballe on /13/7/18.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

enum ZGestureType:Int { case tap = 1, longpress = 2, pan = 4, pinch = 8, swipe = 16, rotation = 32 }
enum ZGestureState:Int { case began = 1, ended = 2, changed = 4, possible = 8, canceled = 16, failed = 32 }

typealias ZViewContentMode = UIViewContentMode
public typealias ZNativeView = UIView

var collapsedViews = [UIView:ZContainerView]()

public protocol ZView {
    var  objectName: String { get set }
    var  Usable: Bool { get set }
    var  Alpha: Double { get }
    func SetAlpha(_ a: Double)
    func SetOpaque(_ opaque:Bool)
    func View() -> UIView
    func Child(_ path: String) -> UIView?
    func DumpTree()
    func Pop(animated:Bool, done:(()->Void)?)
    func RemoveFromParent()
    func Show(_ show:Bool)
    func IsVisible() -> Bool
    func Unfocus()
    func Focus()
    func Parent() -> ZView?
    func SetBackgroundColor(_ color:ZColor)
    func SetCornerRadius(_ radius:Double)
    func SetStroke(width:Double, color:ZColor)
    func Expose(_ fadeIn:Float)
    func Scale(_ scale:Double)
    func GetContainer() -> ZContainerView?
    func CollapseInParent(collapse:Bool, arrange:Bool)
    func GetContainerAndCellIndex() -> (ZContainerView, Int)?
    func CalculateSize(_ total: ZSize) -> ZSize
}

extension ZView {
    public var Rect: ZRect {
        get { return ZRect(View().frame) }
        set { View().frame = newValue.GetCGRect() }
    }
    public var LocalRect: ZRect {
        return ZRect(size:Rect.size)
    }
    public func SetOpaque(_ opaque:Bool) {
        View().isOpaque = opaque 
    }
    public func Pop(animated:Bool = true, done:(()->Void)? = nil) {
        ZPopTopView(animated:animated, done:done)
    }
    public func Show(_ show:Bool = true) {
        View().isHidden = !show
    }
    public func IsVisible() -> Bool {
        return !View().isHidden
    }
    public func GetBoundsRect() -> ZRect {
        return ZRect(View().bounds)
    }
    public func Child(_ path: String) -> UIView? {
        return getUIViewChild(View(), path: path);
    }
    public func DumpTree() {
        dumpUIViewTree(View(), padding: "")
    }
    public var Usable: Bool {
        get {
            return View().isUserInteractionEnabled
        }
        set {
            View().isUserInteractionEnabled = newValue
            View().alpha = newValue ? 1.0 : 0.3
        }
    }
    public func SetAlpha(_ a: Double) {
        View().alpha = CGFloat(a)
    }
    public var Alpha: Double {
        return Double(View().alpha)
    }
    public func RemoveFromParent() {
        if let s = View().superview as? ZContainerView {
            s.DetachChild(View())
        }
        View().removeFromSuperview()
    }
    public func Unfocus() {
        View().resignFirstResponder()
    }
    public func Focus() {
        View().becomeFirstResponder()
    }
    public func Parent() -> ZView? {
        if let v = View().superview as? ZView {
            return v
        }
        return nil
    }
    public func SetBackgroundColor(_ color:ZColor) {
        View().backgroundColor = color.color
    }
    public func SetDropShadow(_ delta:ZSize = ZSize(3, 3), blur:Float32 = 3, color:ZColor = ZColor.Black()) {
        View().layer.shadowOffset = delta.GetCGSize()
        View().layer.shadowColor = color.color.cgColor
        View().layer.shadowRadius = CGFloat(blur)
        View().layer.shadowOpacity = 1
        View().layer.masksToBounds = false
    }
    public func SetDropShadowOff() {
        View().layer.shadowOffset = CGSize.zero
        View().layer.shadowRadius = 0
        View().layer.shadowOpacity = 0
    }
    public func SetCornerRadius(_ radius:Double) {
        View().layer.masksToBounds = true
        View().layer.cornerRadius = CGFloat(radius)
    }
    public func SetStroke(width:Double, color:ZColor) {
        View().layer.borderWidth = CGFloat(width)
        View().layer.borderColor = color.rawColor.cgColor
    }
    public func Expose(_ fadeIn:Float = 0) {
        View().setNeedsDisplay()
    }
    
    public func Scale(_ scale:Double) {
        View().transform = CGAffineTransform.identity.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
    }
    
    public func GetContainer() -> ZContainerView? {
        if let c = View().superview as? ZContainerView {
            return c
        }
        if let c = collapsedViews[self.View()] {
            return c
        }
        return nil
    }
    
    public func CollapseInParent(collapse:Bool = true, arrange:Bool = false) {
        if let c = GetContainer() {
            if collapse {
                collapsedViews[self.View()] = c
            } else {
                collapsedViews.removeValue(forKey:self.View())
            }
            c.CollapseChild(self, collapse:collapse, arrange:arrange)
        }
    }
    
    public func GetContainerAndCellIndex() -> (ZContainerView, Int)? {
        if let container = GetContainer() {
            for (i, c) in container.cells.enumerated() {
                if c.view == View() {
                    return (container, i)
                }
            }
        }
        return nil
    }
    
    public func GetViewRenderedAsImage() -> ZImage? {
        UIGraphicsBeginImageContextWithOptions(View().bounds.size, View().isOpaque, 0.0);
        View().layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return image
    }
    
    public func CalculateSize(_ total: ZSize) -> ZSize {
        return ZSize(10, 10)
    }
}

func zRemoveNativeViewFromParent(_ view:ZNativeView, detachFromContainer:Bool) {
    view.removeFromSuperview()
    if detachFromContainer, let p = view.superview as? ZContainerView {
        p.DetachChild(view)
    }
}

func zAddNativeView(_ view:ZNativeView, toParent:ZNativeView, index:Int? = nil) {
    if index != nil {
        toParent.insertSubview(view, at:index!)
    } else {
        toParent.addSubview(view)
    }
}

func ZViewSetRect(_ view:ZView, rect:ZRect) { // this is needed as setting Rect = xxx gives "Cannot assign to property: 'self' is immutable" sometimes, since above is extension?
    view.View().frame = rect.GetCGRect()
}

func dumpUIViewTree(_ view: UIView, padding: String) {
    if let v = view as? ZView {
        ZDebug.Print(padding + v.objectName)
    } else {
        ZDebug.Print(padding, "\(view)")
    }
    for c in view.subviews as [UIView] {
        dumpUIViewTree(c, padding: padding + "  ")
    }
}

func getUIViewChild(_ view: UIView, path: String) -> UIView? {
    var part = ""
    var vpath = path
    func popPath() -> Bool {
        var parts = ZStr.Split(path, sep: "/")
        if let p = parts.first {
            part = p
            parts.removeLast()
            vpath = ZStr.Join(parts, sep: "/")
            return true
        }
        return false
    }
    if popPath() {
        if part == "*" {
            while !vpath.isEmpty {
                let v = getUIViewChild(view, path:vpath)
                if v != nil {
                    return v
                }
            }
        }
        let i = Int(part)
        let upper = (part == part.uppercased())
        for c in view.subviews as [UIView]{
            if i != nil {
                if c.tag == i! {
                    return (c as UIView)
                }
                return nil
            } else if upper {
                let name = "\(c)"
                if part == name {
                    if !vpath.isEmpty {
                        return getUIViewChild(c, path:vpath)
                    }
                    return c;
                }
            } else if let v = c as? ZView {
                if v.objectName == part {
                    return c
                }
            }
        }
    }    
    return nil
}

struct ZTouchInfo : ZCopy {
//    weak var tapTarget: ZCustomView? = nil
    var touchDownRepeatSecs = 0.0
    var touchDownRepeats = 0
    let touchDownRepeatTimer = ZRepeater()
    var handlePressedInPosFunc: ((_ pos:ZPos)->Void)? = nil
    var doPressed: ((_ pos:ZPos) -> Void)? = nil
}

@discardableResult func touchInfoBeginTracking(touchInfo:ZTouchInfo, view:ZView, touch: UITouch, event: UIEvent?) -> Bool {
    if touchInfo.handlePressedInPosFunc != nil { // touchInfo.tapTarget != nil ||
        if var c = view as? ZControl {
            c.High = true
        }
        view.Expose()
        let pos = ZPos(touch.location(in:view.View()))
//        touchInfo.tapTarget?.HandleTouched(view, state:.began, pos:pos, inside:true)
        if touchInfo.touchDownRepeatSecs != 0 {
            touchInfo.touchDownRepeatTimer.Set(touchInfo.touchDownRepeatSecs) { () in
                touchInfo.doPressed?(pos)
                return true
            }
        }
    }
    return false
}

@discardableResult func touchInfoContinueTracking(touchInfo:ZTouchInfo, view:ZView, touch: UITouch, event: UIEvent?) -> Bool {
    if touchInfo.handlePressedInPosFunc != nil { // touchInfo.tapTarget != nil ||
//        let pos = ZPos(touch.location(in: view.View()))
//        let inside = view.Rect.Contains(pos)
//        touchInfo.tapTarget?.HandleTouched(view, state:.changed, pos:pos, inside:inside)
        touchInfo.touchDownRepeatTimer.Stop()
    }
    return false
}

func touchInfoEndTracking(touchInfo:ZTouchInfo, view:ZView, touch: UITouch?, event: UIEvent?) {
    if !Thread.isMainThread {
        return
    }
    if var c = view as? ZControl {
        c.High = false
    }
    if touchInfo.handlePressedInPosFunc != nil { // touchInfo.tapTarget != nil ||
        let pos = ZPos((touch?.location(in: view.View()))!)
        let inside = view.LocalRect.Contains(pos)
        if inside {
            if let h = touchInfo.handlePressedInPosFunc {
                h(pos)
            }
        }
        touchInfo.touchDownRepeatTimer.Stop()
    }
}

func touchInfoTrackingCanceled(touchInfo:ZTouchInfo, view:ZView, touch: UITouch?, event: UIEvent?) {
//    if touchInfo.tapTarget != nil {
//        touchInfo.tapTarget?.HandleTouched(view, state:.canceled, pos:ZPos(), inside:false)
//    }
    if var c = view as? ZControl {
        c.High = false
    }
    view.Expose()
    touchInfo.touchDownRepeatTimer.Stop()
}


protocol ZViewHandler : class {
    func HandleClose(sender:ZView)
}


