
//
//  zfcolor.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

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
    var HSBA: (Float, Float, Float, Float) {
        var h, s, b, a: CGFloat
        (h, s, b, a) = (0, 0, 0, 0)
        color.getHue(&h, saturation:&s, brightness:&b, alpha:&a)
        return (Float(h), Float(s), Float(b), Float(a))
    }
    
    init(pattern:ZImage) {
        undefined = false
        color = UIColor(patternImage:pattern)
    }
    
    var RGBA: (Float, Float, Float, Float) {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        color.getRed(&r, green:&g, blue:&b, alpha:&a)
        r = min(r, 1)
        g = min(g, 1)
        b = min(b, 1)
        a = min(a, 1)
        return (Float(r), Float(g), Float(b), Float(a))
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
    func OpacityChanged(_ opacity:Float32) -> ZColor {
        let (r, g, b, _) = RGBA
        return ZColor(r:r, g:g, b:b, a:opacity)
    }
    
    func Mix(_ withColor: ZColor, amount: Float32) -> ZColor {
        let (r, g, b, a) = withColor.RGBA
        var (mer, meg, meb, mea) = RGBA
        mer = (1 - amount) * mer + r * amount
        meg = (1 - amount) * meg + g * amount
        meb = (1 - amount) * meb + b * amount
        mea = (1 - amount) * mea + a * amount
        return ZColor(r:mer, g:meg, b:meb, a:mea)
    }
    
    func MultipliedBrightness(_ multiply: Float32) -> ZColor {
        let (h, s, b, a) = HSBA
        return ZColor(h:h, s:s, b:b * multiply, a:a)
    }
    
    func AlteredContrast(_ contrast:Float) -> ZColor {
        let multi = pow((1 + contrast) / 1, 2)
        var (r, g, b, a) = RGBA
        r = (r - 0.5) * multi + 0.5
        g = (g - 0.5) * multi + 0.5
        b = (b - 0.5) * multi + 0.5
        return ZColor(r:r, g:g, b:b, a:a)
    }
    
    func GetContrastingGray() -> ZColor {
        let g = GrayScale
        if g < 0.5 {
            return ZColor.White()
        }
        return ZColor.Black()
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


