//
//  ZViewPresenter.swift
//
//  Created by Tor Langballe on /22/9/14.
//

import UIKit
import MapKit
import AVFoundation

var forcingRotationForPortraitOnly = false

func ZGetViewControllerForView(_ view:ZView, base:UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    if let presented = base?.presentedViewController {
        if base!.view == view.View() {
            return base
        }
        return ZGetTopViewController(base:presented)
    }
    return base
}

func ZGetTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    /*
    if let nav = base as? UINavigationController {
        return ZGetTopViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
        if let selected = tab.selectedViewController {
            return ZGetTopViewController(base: selected)
        }
    }
    */
    if let presented = base?.presentedViewController {
        return ZGetTopViewController(base: presented)
    }
    return base
}

func ZGetTopZViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> ZViewController? {
    if let vc = ZGetTopViewController(base:base) {
        if let v = vc as? ZViewController {
            return v
        }
    }
    return nil
}

enum ZTransitionType: Int { case none, fromLeft, fromRight, fromTop, fromBottom, fade, reverse }

class ZViewController : UIViewController, UIViewControllerTransitioningDelegate, // FBSDKSharingDelegate
                        UIImagePickerControllerDelegate, UINavigationControllerDelegate { // MKMapViewDelegate
    
    var facebookShareDone:((_ sent:Bool) -> Void)? = nil // stupid shit needs to be here since share assums controller is delegate
    var imagePickerDone:((_ image:ZImage?)->Void)? = nil

    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerDone?(nil)
        picker.dismiss(animated: true, completion:nil)
    }

    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let vimage = image.GetRotationAdjusted()
            picker.dismiss(animated: true) { () in
                self.imagePickerDone?(vimage)
            }
        } else {
            picker.dismiss(animated: true, completion:nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        dismiss(animated: true, completion:nil)
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if stack.last?.portraitOnly ?? true {
            return .portrait
        }
        return .allButUpsideDown
    }
    
    open override var shouldAutorotate: Bool {
        if forcingRotationForPortraitOnly {
            return true
        }
        return !(stack.last?.portraitOnly ?? false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if forcingRotationForPortraitOnly {
            return
        }
        super.viewWillTransition(to: size, with:coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            for (i, v) in self.view.subviews.enumerated() { // make this use stack, better for portraitOnly too
                if var cv = v as? ZContainerView {
                    if i < self.view.subviews.count - 1 && cv.portraitOnly {
                        continue
                    }
                    let uArea = stack[i].useableArea
                    cv.SetAsFullView(useableArea:uArea)
                    cv.HandleRotation()
                    cv.Rect = ZRect(size:ZSize(size))
                    cv.RangeChildren() { (view) in
                        if let tv = view as? ZTableView {
                            tv.ReloadData()
                        }
                        return true
                    }
                    cv.ArrangeChildren()
                }
            }
        }, completion: { (context) in
            print("viewWillTransitionToSize done")
        })
    }

    override func viewDidLayoutSubviews() {
        for s in self.view.subviews {
            if let v = s as? ZCustomView {
                v.HandleTransitionedToSize()
            }
        }
    }    
}

func setTransition(_ view:UIView, transition:ZTransitionType, screen:ZRect, fade:Float) {
    var me = screen
    var out = me
    switch transition {
        case .fromLeft:
            out.pos.x += -me.Max.x

        case .fromRight:
            out.pos.x += screen.size.w - me.pos.x

        case .fromTop:
            out.pos.y += -me.Max.y

        case .fromBottom:
            out.pos.y += screen.size.h - me.pos.y

        default:
            break
    }
    view.alpha = CGFloat(fade)
    view.frame = out.GetCGRect()
}

struct Attributes {
    var duration:Double = 0
    var transition:ZTransitionType = .none
    var oldTransition:ZTransitionType = .none
    var lightContent: Bool = true
    var useableArea: Bool = true
    var portraitOnly = false
}

var stack = [Attributes]()
func ZPresentView(_ view:ZView, duration:Double = 0.5, transition:ZTransitionType = .none, fadeToo:Bool = false, oldTransition:ZTransitionType = .reverse, makeFull:Bool = true, useableArea:Bool = false, deleteOld:Bool = false, lightContent:Bool = true, portraitOnly:Bool? = nil, done:(()->Void)? = nil) {
    view.View().isUserInteractionEnabled = false
    var oldView:UIView? = nil
    let win = UIApplication.shared.keyWindow
    if deleteOld {
        stack.removeLast()
    }
    var po = false
    if let cv = view as? ZContainerView {
        po = portraitOnly ?? cv.portraitOnly
    }
    stack.append(Attributes(duration:duration, transition:transition, oldTransition:oldTransition, lightContent:lightContent, useableArea:useableArea, portraitOnly:po))
    let topView = win?.subviews.first
    var voldTransition = oldTransition

    if makeFull {
        if let v = view.View() as? ZContainerView {
            v.SetAsFullView(useableArea:useableArea)
            v.ArrangeChildren()
        }
    }

    topView?.endEditing(true)
    if voldTransition != .none {
        oldView = topView!.subviews.last
        if voldTransition == .reverse {
            switch transition {
                case .fromLeft  : voldTransition = .fromRight
                case .fromRight : voldTransition = .fromLeft
                case .fromTop   : voldTransition = .fromBottom
                case .fromBottom: voldTransition = .fromTop
                default: break
            }
        }
    }
    if oldView == topView {
        oldView = nil
        let vc = ZViewController()
        vc.view = view.View()
        view.View().isUserInteractionEnabled = true
        win!.rootViewController?.present(vc, animated:false) { () in done?() }
        return
    }
    if let cv = view as? ZCustomView {
        if !cv.objectName.isEmpty {
//!            mainAnalytics.SetViewName(cv.objectName)
        }
        cv.HandleOpening()
    }
    view.Show(false)
    topView!.addSubview(view.View())
    ZScreen.SetStatusBarForLightContent(lightContent)
    setTransition(view.View(), transition:transition, screen:ZRect(topView!.frame), fade:0)
    view.Show(true)
    oldView?.isHidden = false
    ZAnimation.Do(duration:duration, animations:{ () in
        if oldView != nil {
            setTransition(oldView!, transition:voldTransition, screen:ZRect(topView!.frame), fade:0)
        }
        setTransition(view.View(), transition:.none, screen:ZRect(topView!.frame), fade:1)
    }, completion:{ (Bool) in
        if deleteOld {
            assert(oldView != nil)
            if let v = oldView as? ZCustomView {
                v.HandleClosing()
            }
            oldView!.removeFromSuperview()
        } else if voldTransition != .none {
            oldView?.isHidden = true
        }
        ZAccessibilty.SendScreenUpdateNotification()
        view.View().isUserInteractionEnabled = true
        done?()
    })
}

func poptop(_ s: inout Attributes) -> UIView? {
    let win = UIApplication.shared.keyWindow
    assert(stack.count > 0)
    s = stack.last ?? Attributes()
    ZScreen.SetStatusBarForLightContent(s.lightContent)
    stack.removeLast()
    
    return  win!.subviews.first
}

weak var lastView:UIView? = nil

func ZPopTopView(namedView:String = "", animated:Bool = true, overrideDuration:Double = -1, overrideTransition:ZTransitionType = .none, done:(()->Void)? = nil) {
    var s = Attributes()
    let topView = poptop(&s)
    let popView = topView!.subviews.last
    if !namedView.isEmpty {
        var start = false
        for s in topView!.subviews where s != popView {
            if let v = s as? ZContainerView {
                if v.objectName == namedView {
                    start = true
                    v.HandleClosing()
                }
            }
            if start {
                s.removeFromSuperview()
            }
        }
    }
    let oldView = topView!.subviews[topView!.subviews.count - 2]
    
    if let pv = popView as! ZContainerView? {
        pv.HandleClosing()
    }
    var t = s.transition
    if overrideTransition != .none {
        t = overrideTransition
    }
    var dur = s.duration
    if overrideDuration != -1 {
        dur = overrideDuration
    }
    oldView.isHidden = false
    if let cv = oldView as? ZContainerView {
        if cv.portraitOnly {
            forcingRotationForPortraitOnly = true
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey:"orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            forcingRotationForPortraitOnly = false
            let uArea = stack.last!.useableArea
            cv.SetAsFullView(useableArea:uArea)
            cv.ArrangeChildren()
        }
        cv.HandleRevealedAgain()
    }
    ZAnimation.Do(duration:animated ? dur : 0,
        animations:{ () in
            setTransition(oldView, transition:.none, screen:ZRect(topView!.frame), fade:1)
            setTransition(popView!, transition:t, screen:ZRect(topView!.frame), fade:0)
    }, completion:{ (Bool) in
        popView?.removeFromSuperview()
        lastView = popView
        ZTimer().Set(1) { () in
            if lastView != nil {
                ZDebug.Print("View not deinited:", lastView)
            }
        }
        done?()
    })
}

func ZGetTopPushedView() -> ZCustomView? {
    let win = UIApplication.shared.keyWindow
    if let v = win?.subviews.first?.subviews.last as? ZCustomView {
        return v
    }
    return nil
}

func ZRecusivelyHandleActivation(activated:Bool) {
    if activated {
        if let cv = ZGetTopPushedView() as? ZContainerView {
            cv.RangeChildren() { (view) in
                if let tv = view as? ZTableView {
                    tv.ReloadData()
                }
                return true
            }
        }
    }
}

