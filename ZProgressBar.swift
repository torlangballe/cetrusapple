//
//  ZProgressBar.swift
//
//  Created by Tor Langballe on /14/12/17.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation

class ZProgressBar: ZCustomView {
    var height:Double
    var width:Double
    var color:ZColor

    fileprivate var value:Double = 0.0
    fileprivate var timer = ZRepeater()
    var Value:Double {
        get { return value }
        set {
            value = newValue
            Expose()
        }
    }
    
    init(height:Double = 2.0, width:Double = 100.0, color:ZColor = ZColor.Blue(), value:Double = 0.0) {
        self.height = height
        self.width = width * ZScreen.SoftScale
        self.color = color
        self.value = value
        super.init(name:"progress")
        minSize = ZSize(self.width, self.height)
        SetBackgroundColor(ZColor.Clear())
        SetCornerRadius(height / 2.0)
    }
    
    override func HandleClosing() {
        ZDebug.Print("HandleClosing progress")
        timer.Stop()
    }
    
    func SetUpdate(_ update:(()->Double)? = nil) {
        if update != nil {
            timer.Set(0.2) { [weak self] () in
                let v = update!()
                if v == -1.0 {
                    return false
                }
                self?.Value = v
                return true
            }
        } else {
            timer.Stop()
        }
    }
    
    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        var path = ZPath(rect:rect, corner:ZSize(height / 2, height / 2))
        canvas.SetColor(color.OpacityChanged(0.2))
        canvas.FillPath(path)

        var r = rect
        r.SetMaxX(rect.size.w * Double(value))
        path = ZPath(rect:r, corner:ZSize(height / 2, height / 2))
        canvas.SetColor(color)
        canvas.FillPath(path)
    }
}

