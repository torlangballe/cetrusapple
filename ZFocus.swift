//
//  ZFocus.Swift
//
//  Created by Tor Langballe on 11/19/18.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

struct ZFocus {
    static var color = ZColor(r:0.5, g:0.5, b:1.0)
    static func Draw(_ canvas:ZCanvas, rect:ZRect, corner:Double = 7.0) {
        var w = 4.0 * ZScreen.SoftScale
        let r = rect.Expanded(-2.0 * ZScreen.SoftScale)
        let path = ZPath(rect:r, corner:ZSize(corner, corner) * ZScreen.SoftScale)
        canvas.SetColor(color)
        canvas.StrokePath(path, width:w)
    }
}
