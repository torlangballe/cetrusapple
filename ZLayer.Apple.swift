//
//  ZLayer.swift
//  Zed
//
//  Created by Tor Langballe on /28/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import QuartzCore

typealias ZGradientLayer = CAGradientLayer
typealias ZTextLayer = CATextLayer

class ZLayer: CALayer {
    var animation: CAPropertyAnimation? = nil
    func AnimateImageOnPath(_ path:ZPath, image:ZImage) {
        let a = CAKeyframeAnimation(keyPath:"position")
      a.calculationMode = CAAnimationCalculationMode.paced
      a.fillMode = CAMediaTimingFillMode.forwards
        a.isRemovedOnCompletion = false
      a.rotationMode = CAAnimationRotationMode.rotateAuto
        a.path = path.path
        animation = a
        self.contents = image.cgImage
    }
    
    init(size:ZSize, bounds:ZRect = ZRect.Null) {
        super.init()
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.frame = ZRect(pos:ZPos(0, 0), size:size).GetCGRect()
        self.bounds = bounds.GetCGRect()
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func SetAnimationForView(_ view:ZView, duration:Double, startAtSecs:Double = 0, speed:Float = 1) {
        view.View().layer.setNeedsDisplay()
        view.View().layer.addSublayer(self)
        animation!.repeatCount = Float.infinity
        animation!.duration = duration
        animation!.beginTime = startAtSecs
        animation!.speed = speed;
      animation!.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.linear)
        self.add(animation!, forKey:animation!.keyPath)
    }
    
    static func SetSpeed(_ layer:CALayer, speed:Float) {
        if speed == 0 {
            let time = layer.convertTime(CACurrentMediaTime(), from: nil)
            layer.speed = 0
            layer.timeOffset = time
        } else {
            let pausedTime: CFTimeInterval = layer.timeOffset
            layer.speed = speed
            layer.timeOffset = 0.0
            layer.beginTime = 0.0
            let time: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            layer.beginTime = time
        }
    }
}

