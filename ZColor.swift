
//
//  ZColor.swift
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//
// #package com.github.torlangballe.cetrusandroid

struct ZHSBA : ZCopy {
    var h:Double = 0.0
    var s:Double = 0.0
    var b:Double = 0.0
    var a:Double = 0.0
}

struct ZRGBA : ZCopy {
    var r:Double = 0.0
    var g:Double = 0.0
    var b:Double = 0.0
    var a:Double = 0.0
}

extension ZColor {
    func OpacityChanged(_ opacity:Double) -> ZColor {
        let c = RGBA
        return ZColor(r:c.r, g:c.g, b:c.b, a:opacity)
    }
    
    func Mix(_ withColor: ZColor, amount:Double) -> ZColor {
        let wc = withColor.RGBA
        var c = RGBA
        c.r = (1 - amount) * c.r + wc.r * amount
        c.g = (1 - amount) * c.g + wc.g * amount
        c.b = (1 - amount) * c.b + wc.b * amount
        c.a = (1 - amount) * c.a + wc.a * amount
        return ZColor(r:c.r, g:c.g, b:c.b, a:c.a)
    }
    
    func MultipliedBrightness(_ multiply:Double) -> ZColor {
        let hsba = self.HSBA
        return ZColor(h:hsba.h, s:hsba.s, b:hsba.b * multiply, a:hsba.a)
    }
    
    func AlteredContrast(_ contrast:Double) -> ZColor {
        let multi = ZMath.Pow((Double(1.0 + contrast)) / 1.0, 2.0)
        var c = self.RGBA
        c.r = (c.r - 0.5) * multi + 0.5
        c.g = (c.g - 0.5) * multi + 0.5
        c.b = (c.b - 0.5) * multi + 0.5
        return ZColor(r:c.r, g:c.g, b:c.b, a:c.a)
    }
    
    func GetContrastingGray() -> ZColor {
        let g = GrayScale
        if g < 0.5 {
            return ZColor.White()
        }
        return ZColor.Black()
    }
}


