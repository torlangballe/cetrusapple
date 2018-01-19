//
//  ZAnimation.swift
//  Zed
//
//  Created by Tor Langballe on /9/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ZAnimation {
    static func Do(duration:Float = 0.4, animations:@escaping ()->Void, completion:((_ done:Bool)->Void)? = nil) {
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
        return view.layer.animationKeys()?.count > 0
    }
    
    static func PulseView(_ view:UIView, scale:Float, duration:Float, fromScale:Float = 1, repeatCount:Float = .infinity) {
        animateView(view, from:fromScale, to:scale, duration:duration, type:"transform.scale", repeatCount:repeatCount)
    }

    static func ScaleView(_ view:UIView, scaleTo:Float, duration:Float) {
        animateView(view, from:1, to:scaleTo, duration:duration, type:"transform.scale", repeatCount:1, autoreverses:false)
    }
    
    static func FadeView(_ view:UIView, to:Float, duration:Float, from:Float = 1) {
        animateView(view, from:from, to:to, duration:duration, type:"opacity", repeatCount:0, autoreverses:false)
    }

    static func PulseOpacity(_ view:UIView, to:Float, duration:Float, from:Float = 1, repeatCount:Float = .infinity) {
        animateView(view, from:from, to:to, duration:duration, type:"opacity", repeatCount:repeatCount)
    }
    
    static func RippleWidget(_ view:UIView, duration:Float) {
        let animation = CATransition()
        animation.duration = CFTimeInterval(duration)
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = "rippleEffect"
        view.layer.add(animation, forKey:nil)
    }

    static func MoveViewOnPath(_ view:ZView, path:ZPath, duration:Double, repeatCount:Float = .infinity, begin:Double = 0) {
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
        animation.repeatCount = repeatCount
        animation.beginTime = CFTimeInterval(begin)
        animation.path = path.path
        animation.calculationMode = kCAAnimationPaced;
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)
        view.View().layer.add(animation, forKey:"position")
        if view.View().window == nil {
            view.View().PerformAfterDelay(2.5) { () in
                view.View().layer.add(animation, forKey:key)
            }
        } else {
            view.View().layer.add(animation, forKey:key)
        }
    }

    static func RotateView(_ view:ZView, degreesClockwise:Float = 360, secs:Float, repeatCount:Float = .infinity) {
         let spinAnimation = CABasicAnimation(keyPath:"transform.rotation")
        spinAnimation.toValue = ZMath.DegToRad(Double(degreesClockwise) * Double(ZMath.Sign(Double(secs))))
        spinAnimation.duration = CFTimeInterval(abs(secs))
        spinAnimation.repeatCount = repeatCount
        view.View().layer.add(spinAnimation, forKey:"spinAnimation")
    }
    

    @discardableResult static func AddGradientAnimationToView(_ view:ZView, colors:[ZColor], locations:[[Float]], duration:Float, autoReverse:Bool = false, speed:Float = 1, opacity:Float = 1, min:ZPos = ZPos(0, 0), max:ZPos = ZPos(0, 1)) -> ZGradientLayer {
        
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
        layer.opacity = opacity

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
        group.speed = speed
        layer.add(group, forKey:"animateGradient")
        layer.speed = 1

        view.View().layer.addSublayer(layer)
        layer.setNeedsDisplay()
        
        return layer
    }

    static func SetViewLayerSpeed(_ view:ZView, speed:Float, resetTime:Bool = false) {
        let layer = view.View().layer
        if resetTime {
            layer.speed = speed
        } else {
            if speed == 0.0 {
                let pausedTime = layer.convertTime(CACurrentMediaTime(), from:nil)
                layer.speed = 0.0;
                layer.timeOffset = pausedTime
            } else {
                let pausedTime = layer.timeOffset
                layer.speed = speed
                layer.timeOffset = 0.0
                layer.beginTime = 0.0
                let timeSincePause = layer.convertTime(CACurrentMediaTime(), from:nil) - pausedTime
                layer.beginTime = timeSincePause
            }
        }
    }

    static func FlipViewHorizontal(_ view:UIView, duration:Float = 0.8, left:Bool, animate:(()->Void)? = nil) {
        let trans = left ? UIViewAnimationOptions.transitionFlipFromLeft : UIViewAnimationOptions.transitionFlipFromRight
        UIView.transition(with: view, duration:TimeInterval(duration), options:trans, animations: {
            animate?()
        }, completion:  { finished in
            //HERE you can remove your old view
        })
        //        let  uitrans = left ? UIViewAnimationTransition.flipFromLeft : UIViewAnimationTransition.flipFromRight
    }
}

private func animateView(_ view:UIView, from:Float, to:Float, duration:Float, type:String, repeatCount:Float = .infinity, autoreverses:Bool = true) {
    let animation = CABasicAnimation()
    animation.keyPath = type
    animation.fromValue = from
    animation.toValue = to
    animation.duration = CFTimeInterval(duration)
    animation.repeatCount = repeatCount
    animation.autoreverses = autoreverses
    animation.isRemovedOnCompletion = false
    animation.timeOffset = 0;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
    let key = "ani." + type
    if view.window == nil {
        view.PerformAfterDelay(2.5) { () in
            view.layer.add(animation, forKey:key)
        }
    } else {
        view.layer.add(animation, forKey:key)
    }
}

/*
 
void ZSetWidgetScale(ZWidget *widget, float scale, bool place)
{
    ZRect  r, rc;
    CGRect cr;
    
    r = ZRect(widget->size);
    rc = (r * scale).Centered(r.Center());
    cr = MacZRectToCGRect(rc);
    [ (NSView *)widget->handle setBounds:cr ];
    [ (NSView *)widget->handle setFrame:MacZRectToCGRect(rc + widget->relpos)];
    if(place) {
        widget->PlaceRect(rc);
    }
}

void ZSetWidgetPlacement(ZWidget *widget, const ZRect &rect)
{
    CGRect cr;
    
    cr = MacZRectToCGRect(ZRect(rect.Size()));
    [ (NSView *)widget->handle setBounds:cr];
    [ (NSView *)widget->handle setFrame:MacZRectToCGRect(rect)]; // + widget->relpos)];
}


void ZAnimateTransformWidget(ZWidget *widget, double durationSecs, ZFPos vector, void (^doneHandler)())
{
    #if ZIPHONEOS
        if(widget->handle) {
            CABasicAnimation *a;
            ZFPos            c;
            
            [CATransaction begin];
            a = [CABasicAnimation animation];
            a.keyPath = @"position";
            //        a.fromValue = [NSValue valueWithCGPoint:MacZPosToCGPoint(widget->abspos)];
            c = ZPosI2F(widget->AbsRect().Center());
            a.fromValue = [NSValue valueWithCGPoint:MacZFPosToCGPoint(c)];
            a.toValue = [NSValue valueWithCGPoint:MacZFPosToCGPoint(c + vector)];
            a.duration = durationSecs;
            a.timeOffset = 0;
            a.fillMode = kCAFillModeForwards;
            a.timingFunction = [ CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut ];
            [CATransaction setCompletionBlock:^{
                if(doneHandler) {
                doneHandler();
                }
                }];
            [ [ (NSView *)widget->handle layer ] addAnimation:a forKey:MacZStrToNSStr("myani.position") ];
            [CATransaction commit];
        }
    #endif
}

void ZAnimateWidgetOnPath(ZWidget *widget, ZPath *path, double durationSecs, double repeat, double rotateSecs)
{
    [CATransaction begin];
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.calculationMode = kCAAnimationPaced;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.repeatCount = repeat ? repeat : INFINITY;
    //pathAnimation.rotationMode = @"auto";
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    pathAnimation.duration = durationSecs;
    
    pathAnimation.path = (CGPathRef)path->handle;
    
    [((NSView *)widget->handle).layer addAnimation:pathAnimation forKey:@"myPathAnimation"];
    
    if(rotateSecs) {
        CABasicAnimation *spinAnimation;
        
        spinAnimation = [ CABasicAnimation animationWithKeyPath:@"transform.rotation" ];
        spinAnimation.toValue = [ NSNumber numberWithFloat:ZPI*2 ];
        spinAnimation.duration = rotateSecs;
        spinAnimation.repeatCount = INFINITY;
        [ ((NSView *)widget->handle).layer addAnimation:spinAnimation forKey:@"spinAnimation" ];
    }
    [CATransaction commit];
}



void ZWidgetSetParalax(ZWidget *widget, double shift)
{
UIInterpolatingMotionEffect *interpolationHorizontal;
NSNumber                    *pos, *neg;

pos = [NSNumber numberWithDouble:shift];
neg = [NSNumber numberWithDouble:-shift];
interpolationHorizontal = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
interpolationHorizontal.minimumRelativeValue = pos;
interpolationHorizontal.maximumRelativeValue = neg;
UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
interpolationVertical.minimumRelativeValue = pos;
interpolationVertical.maximumRelativeValue = neg;

[((UIView *)widget->handle) addMotionEffect:interpolationHorizontal];
[((UIView *)widget->handle) addMotionEffect:interpolationVertical];
}
*/
