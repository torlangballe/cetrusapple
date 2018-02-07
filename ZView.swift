//
//  ZView.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

import UIKit

enum ZGestureType:Int { case tap = 1, longpress = 2, pan = 4, pinch = 8, swipe = 16, rotation = 32 }
enum ZGestureState:Int { case began = 1, ended = 2, changed = 4, possible = 8, canceled = 16, failed = 32 }

protocol ZView {
    var objectName: String { get set }
    
    var Usable: Bool { get set }
    func View() -> UIView
    //    func Push(over:ZView?, duration:Float, transition:ZTransitionType, oldTransition:ZTransitionType, makeFull:Bool, useableArea:Bool, deleteOld:Bool, done:(()->Void)?)
    var  Rect: ZRect { get set }
    var  LocalRect: ZRect { get }
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
    func Expose(_ fadeIn:Float)
    //    func ExposeWithFadeIn(fadeIn:Float)
    func Scale(_ scale:Double)
    func GetContainer() -> ZContainerView?
    func CollapseInParent(collapse:Bool, arrange:Bool)
}

typealias ZViewContentMode = UIViewContentMode

var collapsedViews = [UIView:ZContainerView]()

extension ZView {

    var Rect: ZRect {
        get { return ZRect(View().frame) }
        set { View().frame = newValue.GetCGRect() }
    }
    var LocalRect: ZRect {
        return ZRect(size:Rect.size)
    }
    /*
    func Push(over:ZView? = nil, duration:Float = 0.5, transition:ZTransitionType = .none, oldTransition:ZTransitionType = .reverse, makeFull:Bool = true, useableArea:Bool = true, deleteOld:Bool = false, done:(()->Void)? = nil) {
        ZPresentView(self, duration:duration, transition:transition, oldTransition:oldTransition, makeFull:makeFull, useableArea:useableArea, deleteOld:deleteOld, done:done)
    }
    */
    
    /*
    func Push(duration duration:Float = 0.5, transition:ZTransitionType = .None, fadeSubView: UIView? = nil, makeFull:Bool = true, removeOld:Bool = false, done:(()->Void)? = nil) {
        // http://stackoverflow.com/questions/12741224/ios-modal-viewcontroller-with-transparent-background
        if makeFull {
            if let v = View() as? ZContainerView {
                v.SetAsFullView(useableArea:true)
                v.ArrangeChildren()
            }
        }
        ZPresentView(self, duration:duration, transition:transition, fadeSubView:fadeSubView, removeOld:removeOld, done:done)
    }
    */
    func Pop(animated:Bool = true, done:(()->Void)? = nil) {
        ZPopTopView(animated:animated, done:done)
        //        ZGetViewControllerForView(self)!.dismissViewControllerAnimated(animated, completion:done)
    }
    func Show(_ show:Bool = true) {
        View().isHidden = !show
    }
    func IsVisible() -> Bool {
        return !View().isHidden
    }
    func GetBoundsRect() -> ZRect {
        return ZRect(View().bounds)
    }
    func Child(_ path: String) -> UIView? {
        return getUIViewChild(View(), path: path);
    }
    func DumpTree() {
        dumpUIViewTree(View(), padding: "")
    }
    var Usable: Bool {
        get {
            return View().isUserInteractionEnabled
        }
        set {
            View().isUserInteractionEnabled = newValue
            View().alpha = newValue ? 1.0 : 0.3
        }
    }
    func RemoveFromParent() {
        if let s = View().superview as? ZContainerView {
            s.DetachChild(View())
        }
        View().removeFromSuperview()
    }
    func Unfocus() {
        View().resignFirstResponder()
    }
    func Focus() {
        View().becomeFirstResponder()
    }
    func Parent() -> ZView? {
        if let v = View().superview as? ZView {
            return v
        }
        return nil
    }
    func SetBackgroundColor(_ color:ZColor) {
        View().backgroundColor = color.color
    }
    func SetDropShadow(_ delta:ZSize = ZSize(3, 3), blur:Float32 = 3, color:ZColor = ZColor.Black()) {
        View().layer.shadowOffset = delta.GetCGSize()
        View().layer.shadowColor = color.color.cgColor
        View().layer.shadowRadius = CGFloat(blur)
        View().layer.shadowOpacity = 1
        View().layer.masksToBounds = false
    }
    func SetDropShadowOff() {
        View().layer.shadowOffset = CGSize.zero
        View().layer.shadowRadius = 0
        View().layer.shadowOpacity = 0
    }
    func SetCornerRadius(_ radius:Double) {
        View().layer.masksToBounds = true
        View().layer.cornerRadius = CGFloat(radius)
    }
    func Expose(_ fadeIn:Float = 0) {
        View().setNeedsDisplay()
    }

    func Scale(_ scale:Double) {
        View().transform = CGAffineTransform.identity.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
    }
    
    func GetContainer() -> ZContainerView? {
        if let c = View().superview as? ZContainerView {
            return c
        }
        if let c = collapsedViews[self.View()] {
            return c
        }
        return nil
    }

    func CollapseInParent(collapse:Bool = true, arrange:Bool = false) {
        if let c = GetContainer() {
            if collapse {
                collapsedViews[self.View()] = c
            } else {
                collapsedViews.removeValue(forKey:self.View())
            }
            c.CollapseChild(self, collapse:collapse, arrange:arrange)
        }
    }
    
    func GetViewRenderedAsImage() -> ZImage? {
        UIGraphicsBeginImageContextWithOptions(View().bounds.size, View().isOpaque, 0.0);
        View().layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
    
        return image
    }

}

func dumpUIViewTree(_ view: UIView, padding: String) {
    if let v = view as? ZView {
        ZDebug.Print(padding + v.objectName)
    } else {
        ZDebug.Print(padding + swift.GetClassName(view))
    }
    for c in view.subviews as [UIView] {
        dumpUIViewTree(c, padding: padding + "  ")
    }
}

func getUIViewChild(_ view: UIView, path: String) -> UIView? {
    var part = ""
    var vpath = path
    func popPath() -> Bool {
        var parts = ZStrUtil.Split(path, sep: "/")
        if let p = parts.first {
            part = p
            parts.removeLast()
            vpath = ZStrUtil.Join(parts, sep: "/")
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
                if part ==  swift.GetClassName(c) {
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


protocol ZViewHandler: class {
    func HandleClose(sender:ZView)
}

