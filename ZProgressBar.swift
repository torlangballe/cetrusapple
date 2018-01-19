//
//  ZProgressBar.swift
//  PocketProbe
//
//  Created by Tor Langballe on /14/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import Foundation

class ZProgressBar: ZCustomView {
    var height:Double
    var width:Double
    var color:ZColor

    fileprivate var value:Float = 0
    fileprivate var timer = ZRepeater()
    var Value:Float {
        get { return value }
        set {
            value = newValue
            Expose()
        }
    }
    
    init(height:Double = 2, width:Double = 100, color:ZColor = ZColor.Blue(), value:Float = 0) {
        self.height = height
        self.width = width
        self.color = color
        self.value = value
        super.init(name:"progress")
        minSize = ZSize(width, height)
        SetBackgroundColor(ZColor.Clear())
        SetCornerRadius(height/2)
    }
    
    override func HandleClosing() {
        ZDebug.Print("HandleClosing progress")
        timer.Stop()
    }
    
    func SetUpdate(_ update:(()->Float)? = nil) {
        if update != nil {
            timer.Set(0.2, owner:self) { [weak self] () in
                let v = update!()
                if v == -1 {
                    return false
                }
                self?.Value = v
                return true
            }
        } else {
            timer.Stop()
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        var r = rect
        r.Max.x = rect.size.w * Double(value)
        let path = ZPath(rect:r, corner:ZSize(height / 2, height / 2))
        canvas.SetColor(color)
        canvas.FillPath(path)
    }
}

