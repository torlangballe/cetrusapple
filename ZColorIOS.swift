//
//  ZColorIOS.swift
//
//  Created by Tor Langballe on /13/7/18.
//
// #package com.github.torlangballe.CetrusAndroid

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
    init(white:Double, a:Double = 1.0) {
        undefined = false
        color = UIColor(white:CGFloat(white), alpha:CGFloat(a))
    }
    init(r:Double, g:Double, b:Double, a:Double = 1.0) {
        undefined = false
        color = UIColor(red:CGFloat(r), green:CGFloat(g), blue:CGFloat(b), alpha:CGFloat(a))
    }
    init(h: Double, s: Double, b: Double, a: Double = 1.0) {
        undefined = false
        color = UIColor(hue:CGFloat(h), saturation:CGFloat(s), brightness:CGFloat(b), alpha:CGFloat(a))
    }
    var HSBA: ZHSBA {
        var h, s, b, a: CGFloat
        (h, s, b, a) = (0, 0, 0, 0)
        color.getHue(&h, saturation:&s, brightness:&b, alpha:&a)
        var hsba = ZHSBA()
        hsba.h = Double(h)
        hsba.s = Double(h)
        hsba.b = Double(h)
        hsba.a = Double(h)
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
        c.r = Double(min(r, 1))
        c.g = Double(min(g, 1))
        c.b = Double(min(b, 1))
        c.a = Double(min(a, 1))
        return c
    }
    
    var GrayScaleAndAlpha: (Double, Double) { // white, alpha
        var w, a: CGFloat
        (w, a) = (0, 0)
        color.getWhite(&w, alpha:&a)
        return (Double(w), Double(a))
    }
    var GrayScale: Double {
        var w:CGFloat = 0
        var a:CGFloat = 0
        color.getWhite(&w, alpha:&a)
        return Double(w)
    }
    var Opacity: Double {
        var w, a: CGFloat
        (w, a) = (0, 0)
        color.getWhite(&w, alpha:&a)
        return Double(a)
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
