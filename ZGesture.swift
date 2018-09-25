//
//  ZGesture.swift
//  PocketProbe
//
//  Created by Tor Langballe on /21/9/18.
//  Copyright © 2018 Bridgetech. All rights reserved.
//

import Foundation
/*
protocol ZGesture {
}

enum ZGestureType:Int { case tap = 1, longpress = 2, pan = 4, pinch = 8, swipe = 16, rotation = 32 }
enum ZGestureState:Int { case began = 1, ended = 2, changed = 4, possible = 8, canceled = 16, failed = 32 }

func zAddGestureTo(_ view:ZView, handler:ZCustomView, type:ZGestureType, taps:Int = 1, touches:Int = 1, duration:Double = 0.8, movement:Double = 10, dir:ZAlignment = .None) {
    view.View().isUserInteractionEnabled = true
    
    switch type {
    case .tap:
        let gtap = UITapGestureRecognizer(target:handler, action:#selector(handler.handleGesture(_:)))
        gtap.numberOfTapsRequired = taps
        gtap.numberOfTouchesRequired = touches
        gtap.cancelsTouchesInView = true
        addGesture(gtap, view:view, handler:handler)
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
        let glong = UILongPressGestureRecognizer(target:handler, action:#selector(handler.handleGesture(_:)))
        glong.numberOfTapsRequired = taps - 1
        glong.numberOfTouchesRequired = touches
        glong.allowableMovement = CGFloat(movement)
        glong.minimumPressDuration = CFTimeInterval(duration)
        addGesture(glong, view:view, handler:handler)
        view.View().addGestureRecognizer(glong)
        
    case .pan:
        let gpan = UIPanGestureRecognizer(target:handler, action:#selector(handler.handleGesture(_:)))
        gpan.minimumNumberOfTouches = touches
        addGesture(gpan, view:view, handler:handler)
        view.View().addGestureRecognizer(gpan)
        
    case .pinch:
        let gpinch = UIPinchGestureRecognizer(target:handler, action:#selector(handler.handleGesture(_:)))
        addGesture(gpinch, view:view, handler:handler)
        view.View().addGestureRecognizer(gpinch)
        
    case .swipe:
        let gswipe = UISwipeGestureRecognizer(target:handler, action:#selector(handler.handleGesture(_:)))
        gswipe.numberOfTouchesRequired = touches
        switch dir {
        case ZAlignment.Left  : gswipe.direction = UISwipeGestureRecognizerDirection.left
        case ZAlignment.Right : gswipe.direction = UISwipeGestureRecognizerDirection.right
        case ZAlignment.Top   : gswipe.direction = UISwipeGestureRecognizerDirection.up
        case ZAlignment.Bottom: gswipe.direction = UISwipeGestureRecognizerDirection.down
        default:
            return
        }
        addGesture(gswipe, view:view, handler:handler)
        view.View().addGestureRecognizer(gswipe)
        
    case .rotation:
        let grot = UIRotationGestureRecognizer(target:handler, action:#selector(handler.handleGesture(_:)))
        addGesture(grot, view:view, handler:handler)
        view.View().addGestureRecognizer(grot)
    }
}

func zHandleGesture(_ g: UIGestureRecognizer) {
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

private func addGesture(_ g: UIGestureRecognizer, view:ZView, handler:ZCustomView) {
    view.View().isUserInteractionEnabled = true
    g.delaysTouchesEnded = true
    g.delegate = handler
}

*/
