//
//  ZFont.swift
//  Zed
//
//  Created by Tor Langballe on /22/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

typealias ZFont = UIFont

// http://iosfonts.com

extension ZFont {
    public enum Style:String { case normal = "", bold = "bold", italic = "italic" }
    
    public convenience init?(name fontName: String, style:Style = .normal, _ pointsize:Float64) {
        var vfontName = fontName
        if style != .normal {
            vfontName += "-" + style.rawValue
        }
        self.init(name:vfontName, size:CGFloat(pointsize))
    }
    
    static func Nice(_ size:Float64, style:Style = .normal) -> ZFont {
        return ZFont(name:"Helvetica", style:style, size)!
    }
    
    func NewWithSize(_ size:Float64) -> ZFont? {
        return ZFont(name:self.fontName, size)
    }
    
    static var appFont:ZFont = ZFont.Nice(20)
}

/*
class ZFont: UIFont {
    init?(name fontName: String, size fontSize: CGFloat) {
        super.init(name: fontName, size: fontSize)
    }
}
*/

