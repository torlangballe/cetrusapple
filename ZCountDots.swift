//
//  ZCountDots.swift
//  capsulefm
//
//  Created by Tor Langballe on /22/4/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZCountDots: ZStackView {
    var circleWidth:Float = 16
    var circleAlign = ZAlignment.Right
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(name:String = "dots") {
        super.init(name:name)
        SetFGColor(ZColor(white:1, a:0.5))
        space = 4
        isAccessibilityElement = true
    }
    
    var Level: Int {
        get {
            return FindCellWithName("filled") ?? -1
        }
        set {
            var n = newValue
            if let i = FindCellWithName("filled") {
                let c = cells.remove(at: i)
                if n == -1 {
                    n = cells.count
                }
                cells.insert(c, at:n)
            }
        }
    }
    
    var Count: Int {
        get { return cells.count }
        set {
            if newValue > cells.count {
                for _ in 0 ..< (newValue - cells.count) {
                    addCircle()
                }
            }
            let count = cells.count - newValue
            for _ in 0 ..< count {
                RemoveNamedChild("clear")
            }
            accessibilityLabel = ZTS("dot navigator, %d deep, level %d", args:cells.count, Level) // VO name of navigation backskip dots
            accessibilityTraits = UIAccessibilityTraitButton
            //!!!!            self.Show(newValue > 1)
        }
    }
    
    fileprivate func addCircle() {
        let count = cells.count
        let filled = (count == 0)
        var v = ZCustomView(name:filled ? "filled" : "clear")
        v.Usable = false
        v.minSize = ZSize(circleWidth, circleWidth)
        v.Rect = ZRect(size:v.minSize)
        v.drawHandler = { (rect: ZRect, canvas: ZCanvas, view:ZCustomView) in
            let path = ZPath()
            path.AddOval(inrect:v.LocalRect.Expanded(-1))
            canvas.SetColor(self.foregroundColor)
            if filled {
                canvas.FillPath(path)
            } else {
                canvas.StrokePath(path, width:2)
            }
        }
        Add(v, align:circleAlign | .VertCenter)
        //!!!!        Show(count > 0)
    }
}



