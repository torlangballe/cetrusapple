//
//  ZColorIOS.swift
//
//  Created by Tor Langballe on /13/7/18.
//
// #package com.github.torlangballe.zetrus

import Foundation

import UIKit

class ZColor : Hashable {
    static func ==(lhs: ZColor, rhs: ZColor) -> Bool { return lhs.color == rhs.color }
    var hashValue: Int { get { return color.hashValue } }
    
    var undefined: Bool
    var color: UIColor
    
    init() {
        undefined = true
        color = UIColor()
    }
    init(color: UIColor) {
        undefined = false
        self.color = color
    }
    init(white:Float32, a:Float32 = 1.0) {
        undefined = false
        color = UIColor(white:CGFloat(white), alpha:CGFloat(a))
    }
    init(r:Float32, g:Float32, b:Float32, a:Float32 = 1.0) {
        undefined = false
        color = UIColor(red:CGFloat(r), green:CGFloat(g), blue:CGFloat(b), alpha:CGFloat(a))
    }
    init(h: Float32, s: Float32, b: Float32, a: Float32 = 1.0) {
        undefined = false
        color = UIColor(hue:CGFloat(h), saturation:CGFloat(s), brightness:CGFloat(b), alpha:CGFloat(a))
    }
    var HSBA: ZHSBA {
        var h, s, b, a: CGFloat
        (h, s, b, a) = (0, 0, 0, 0)
        color.getHue(&h, saturation:&s, brightness:&b, alpha:&a)
        var hsba = ZHSBA()
        hsba.h = Float(h)
        hsba.s = Float(h)
        hsba.b = Float(h)
        hsba.a = Float(h)
        return hsba
    }
    
    init(pattern:ZImage) {
        undefined = false
        color = UIColor(patternImage:pattern)
    }
    
    var RGBA: ZRGBA {
        var r, g, b, a: CGFloat
        var c = ZRGBA()
        (r, g, b, a) = (0, 0, 0, 0)
        color.getRed(&r, green:&g, blue:&b, alpha:&a)
        c.r = min(Float(r), 1)
        c.g = min(Float(g), 1)
        c.b = min(Float(b), 1)
        c.a = min(Float(a), 1)
        return c
    }
    
    var GrayScaleAndAlpha: (Float, Float) { // white, alpha
        var w, a: CGFloat
        (w, a) = (0, 0)
        color.getWhite(&w, alpha:&a)
        return (Float(w), Float(a))
    }
    var GrayScale: Float {
        var w:CGFloat = 0
        var a:CGFloat = 0
        color.getWhite(&w, alpha:&a)
        return Float(w)
    }
    var Opacity: Float {
        var w, a: CGFloat
        (w, a) = (0, 0)
        color.getWhite(&w, alpha:&a)
        return Float(a)
    }

    var rawColor: UIColor { return color }
    
    class func White() -> ZColor  { return ZColor(color: UIColor.white)   }
    class func Black() -> ZColor  { return ZColor(color: UIColor.black)   }
    class func Gray() -> ZColor   { return ZColor(color: UIColor.gray)    }
    class func Clear() -> ZColor  { return ZColor(white:0, a:0)                  }
    class func Blue() -> ZColor   { return ZColor(color: UIColor.blue)    }
    class func Red() -> ZColor    { return ZColor(color: UIColor.red)     }
    class func Yellow() -> ZColor { return ZColor(color: UIColor.yellow)  }
    class func Green() -> ZColor  { return ZColor(color: UIColor.green)   }
    class func Orange() -> ZColor { return ZColor(color: UIColor.orange)  }
}
