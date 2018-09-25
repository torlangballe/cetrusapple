//
//  ZFont.swift
//  Zed
//
//  Created by Tor Langballe on /22/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

typealias ZFont = UIFont

extension ZFont {
    public enum Style:String { case normal = "", bold = "bold", italic = "italic" }
    
    public convenience init?(name fontName: String, _ pointsize:Double, style:Style = .normal) {
        var vfontName = fontName
        if style != .normal {
            vfontName += "-" + style.rawValue
        }
        self.init(name:vfontName, size:CGFloat(pointsize))
    }
    
static func Nice(_ size:Double, style:Style = .normal) -> ZFont {
        return ZFont(name:"Helvetica", size, style:style)!
    }
    
    func NewWithSize(_ size:Double) -> ZFont? {
        return ZFont(name:self.fontName, size)
    }
    
    static var appFont:ZFont = ZFont.Nice(20)
}

