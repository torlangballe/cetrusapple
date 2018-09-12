//
//  ZGLView.swift
//  capsulefm
//
//  Created by Tor Langballe on /4/5/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//
//  http://www.raywenderlich.com/5223/beginning-opengl-es-2-0-with-glkit-part-1
//  https://developer.apple.com/library/ios/documentation/3ddrawing/conceptual/opengles_programmingguide/introduction/introduction.html

import UIKit
import CoreImage
import GLKit

protocol ZGLViewDelegate {
    func DoDraw(_ rect:ZRect)
}

class ZGLView : GLKView, ZView, GLKViewControllerDelegate {

    var inited = false
    var drawFramesPerSec = 60
    var zdelegate: ZGLViewDelegate? = nil
    var animationTimer = ZRepeater()
    var drawTime = 0.0
    var start = 0.0
    var timeManualIncrease = false
    var objectName = "glview"
    
    init(rect:ZRect, fps:Int) {
        super.init(frame:rect.GetCGRect(), context: EAGLContext(api: .openGLES2)!)
        timeManualIncrease = false;
        drawFramesPerSec = fps

        self.drawableDepthFormat = GLKViewDrawableDepthFormat.formatNone
        self.contentScaleFactor = UIScreen.main.scale
        
        let viewController = GLKViewController(nibName:nil, bundle:nil)
        viewController.view = self
        viewController.delegate = self
        viewController.preferredFramesPerSecond = drawFramesPerSec
        viewController.isPaused = false
        self.window?.rootViewController = viewController
        start = ZTime.Now().SecsSinceEpoc
        drawTime = 0
        //        if drawFramesPerSec > 0 {
        //    setDrawFramesPerSec(drawFramesPerSec)
        // }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func View() -> UIView {
        return self
    }
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
    }

    override func draw(_ rect:CGRect) {
    
        if timeManualIncrease {
            drawTime += 1.0 / Double(drawFramesPerSec)
        } else {
            drawTime = ZTime.Now().SecsSinceEpoc - start
        }
        doDraw(ZRect(rect))
        inited = true
    }
    
    func doDraw(_ rect:ZRect) {
        zdelegate?.DoDraw(rect)
    }
    
    func Setup2d() {
        //    self.setPixelFlat()
    }
}

