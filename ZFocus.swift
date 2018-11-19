//
//  ZView.swift
//  BoxProbe
//
//  Created by Tor Langballe on 11/19/18.
//  Copyright © 2018 Bridge Technologies. All rights reserved.
//

import UIKit

struct ZFocus {
    static var color = ZColor(r:0.5, g:0.5, b:1)
    static func Draw(_ canvas:ZCanvas, rect:ZRect, corner:Double = 5.0) {
        var w = 5.0
        let r = rect.Expanded(-2)
        var opacity = 0.4
        let path = ZPath(rect:r, corner:ZSize(corner, corner))
        while w > 0 {
            let c = color.OpacityChanged(opacity)
            canvas.SetColor(c)
            canvas.StrokePath(path, width:w)
            w -= 2.0
            opacity += 0.3
        }
    }
}
