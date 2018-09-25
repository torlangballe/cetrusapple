//
//  ZAnimation.swift
//  Zed
//
//  Created by Tor Langballe on /9/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZAnimation {
    static func Do(duration:Double = 0.4, animations:@escaping ()->Void, completion:((_ done:Bool)->Void)? = nil) {
        if duration == 0 {
            animations()
            completion?(true)
        } else {
            let o = UIViewAnimationOptions.allowUserInteraction
            UIView.animate(withDuration: TimeInterval(duration), delay:0, options:[o], animations:animations, completion:completion)
        }
    }

    static func RemoveAllFromView(_ view:UIView) {
        view.layer.removeAllAnimations()
    }
    
    static func ViewHasAnimations(_ view:UIView) -> Bool {
        return view.layer.animationKeys()?.count ?? 0 > 0
    }
    
    static func PulseView(_ view:UIView, scale:Double, duration:Double, fromScale:Double = 1, repeatCount:Double = .infinity) {
        animateView(view, from:fromScale, to:scale, duration:duration, type:"transform.scale", repeatCount:repeatCount)
    }

    static func ScaleView(_ view:UIView, scaleTo:Double, duration:Double) {
        animateView(view, from:1, to:scaleTo, duration:duration, type:"transform.scale", repeatCount:1, autoreverses:false)
    }
    
    static func FadeView(_ view:UIView, to:Double, duration:Double, from:Double = 1) {
        animateView(view, from:from, to:to, duration:duration, type:"opacity", repeatCount:0, autoreverses:false)
    }

    static func PulseOpacity(_ view:UIView, to:Double, duration:Double, from:Double = 1, repeatCount:Double = .infinity) {
        animateView(view, from:from, to:to, duration:duration, type:"opacity", repeatCount:repeatCount)
    }
    
    static func RippleWidget(_ view:UIView, duration:Double) {
        let animation = CATransition()
        animation.duration = CFTimeInterval(duration)
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = "rippleEffect"
        view.layer.add(animation, forKey:nil)
    }

    static func MoveViewOnPath(_ view:ZView, path:ZPath, duration:Double, repeatCount:Double = .infinity, begin:Double = 0) {
        let key = "position"
        let animation = CAKeyframeAnimation(keyPath:key)
        animation.calculationMode = kCAAnimationLinear
        animation.fillMode = kCAFillModeForwards
        var vduration = duration
        if vduration < 0 {
            vduration *= -1
            animation.speed = -1
        }
        animation.duration = CFTimeInterval(vduration)
        animation.isRemovedOnCompletion = false
        animation.rotationMode = kCAAnimationRotateAuto
        animation.repeatCount = Float(repeatCount)
        animation.beginTime = CFTimeInterval(begin)
        animation.path = path.path
        animation.calculationMode = kCAAnimationPaced;
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)
        view.View().layer.add(animation, forKey:"position")
        if view.View().window == nil {
            ZPerformAfterDelay(2.5) { () in
                view.View().layer.add(animation, forKey:key)
            }
        } else {
            view.View().layer.add(animation, forKey:key)
        }
    }

    static func RotateView(_ view:ZView, degreesClockwise:Double = 360, secs:Double, repeatCount:Double = .infinity) {
         let spinAnimation = CABasicAnimation(keyPath:"transform.rotation")
        spinAnimation.toValue = ZMath.DegToRad(Double(degreesClockwise) * Double(sign(Double(secs))))
        spinAnimation.duration = CFTimeInterval(abs(secs))
        spinAnimation.repeatCount = Float(repeatCount)
        view.View().layer.add(spinAnimation, forKey:"spinAnimation")
    }
    

    @discardableResult static func AddGradientAnimationToView(_ view:ZView, colors:[ZColor], locations:[[Double]], duration:Double, autoReverse:Bool = false, speed:Double = 1, opacity:Double = 1, min:ZPos = ZPos(0, 0), max:ZPos = ZPos(0, 1)) -> ZGradientLayer {
        
        let layer = ZGradientLayer()
        let s = view.View().frame.size
        layer.frame = CGRect(x:-8, y:-12, width:s.width + 16, height:s.height + 20)
        
        var a = [CGColor]()
        for c in colors {
            a.append(c.color.cgColor)
        }
        layer.colors = a
        layer.startPoint = min.GetCGPoint()
        layer.endPoint = max.GetCGPoint()
        layer.opacity = Float(opacity)

        layer.locations = locations[0] as [NSNumber]?
        
        var animations = [CABasicAnimation]()
        for i in 0 ..< locations.count - 1 {
            let animation = CABasicAnimation(keyPath:"locations")
            animation.fromValue = locations[i]
            animation.toValue = locations[(i+1)%locations.count]
            animation.duration	= CFTimeInterval(duration)
            animation.repeatCount = 0;
            animation.autoreverses = false
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeForwards;
            animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)
            animation.beginTime = CFTimeInterval(duration) * CFTimeInterval(i)
            animations.append(animation)
        }
        
        let group = CAAnimationGroup()
        group.duration = CFTimeInterval(locations.count) * CFTimeInterval(duration)
        group.isRemovedOnCompletion = true
        group.repeatCount = .infinity
        group.fillMode = kCAFillModeForwards;
        group.autoreverses = autoReverse;
        group.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)
        group.animations = animations
        group.speed = Float(speed)
        layer.add(group, forKey:"animateGradient")
        layer.speed = 1

        view.View().layer.addSublayer(layer)
        layer.setNeedsDisplay()
        
        return layer
    }

    static func SetViewLayerSpeed(_ view:ZView, speed:Double, resetTime:Bool = false) {
        let layer = view.View().layer
        if resetTime {
            layer.speed = Float(speed)
        } else {
            if speed == 0.0 {
                let pausedTime = layer.convertTime(CACurrentMediaTime(), from:nil)
                layer.speed = 0.0;
                layer.timeOffset = pausedTime
            } else {
                let pausedTime = layer.timeOffset
                layer.speed = Float(speed)
                layer.timeOffset = 0.0
                layer.beginTime = 0.0
                let timeSincePause = layer.convertTime(CACurrentMediaTime(), from:nil) - pausedTime
                layer.beginTime = timeSincePause
            }
        }
    }

    static func FlipViewHorizontal(_ view:UIView, duration:Double = 0.8, left:Bool, animate:(()->Void)? = nil) {
        let trans = left ? UIViewAnimationOptions.transitionFlipFromLeft : UIViewAnimationOptions.transitionFlipFromRight
        UIView.transition(with: view, duration:TimeInterval(duration), options:trans, animations: {
            animate?()
        }, completion:  { finished in
            //HERE you can remove your old view
        })
        //        let  uitrans = left ? UIViewAnimationTransition.flipFromLeft : UIViewAnimationTransition.flipFromRight
    }
}

private func animateView(_ view:UIView, from:Double, to:Double, duration:Double, type:String, repeatCount:Double = .infinity, autoreverses:Bool = true) {
    let animation = CABasicAnimation()
    animation.keyPath = type
    animation.fromValue = from
    animation.toValue = to
    animation.duration = CFTimeInterval(duration)
    animation.repeatCount = Float(repeatCount)
    animation.autoreverses = autoreverses
    animation.isRemovedOnCompletion = false
    animation.timeOffset = 0;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
    let key = "ani." + type
    view.layer.add(animation, forKey:key)
}

