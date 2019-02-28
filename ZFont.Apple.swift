//
//  ZFont.swift
//  Zed
//
//  Created by Tor Langballe on /22/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

#if os(macOS)
import AppKit
typealias ZFont = NSFont
#else
import UIKit
typealias ZFont = UIFont
#endif

//typealias ZFont = UIFont

extension ZFont {
    public enum Style:String { case normal = "", bold = "bold", italic = "italic" }
    
    public convenience init?(name fontName: String, _ pointsize:Double, style:Style = .normal) {
        var vfontName = fontName
        if style != .normal {
            vfontName += "-" + ZStr.TitleCase(style.rawValue)
        }
        self.init(name:vfontName, size:CGFloat(pointsize))
    }
    
    #if os(macOS)
    open var lineHeight: CGFloat { get {
            return 20
        }
    }
    #endif
    
    static func Nice(_ size:Double, style:Style = .normal) -> ZFont {
        #if os(macOS)
        let scale = 1.0
        #else
        let scale = ZScreen.SoftScale
        #endif
        return ZFont(name:"Helvetica", size * scale, style:style)!
    }
    
    func NewWithSize(_ size:Double) -> ZFont? {
        return ZFont(name:self.fontName, size)
    }
    
    static var appFont:ZFont = ZFont.Nice(20)
}

