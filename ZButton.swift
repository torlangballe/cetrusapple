//
//  ZButton.swift
//
//  Created by Tor Langballe on /14/12/17.
//

// #package com.github.torlangballe.CetrusAndroid

import UIKit

class ZButton : ZShapeView {
    var insets = ZSize()
    
    init(title:String, namedImage:String, w:Double, insets:ZSize = ZSize(6.0, 13.0), titleColor:ZColor = ZColor.White()) {
        super.init(type:ZShapeView.ShapeType.none, minSize:ZSize(w, 44.0))
        self.insets = insets
        image = ZImage(named:namedImage)
        image = image!.Make9PatchImage(capInsets:ZRect(insets.w, insets.h, insets.w, insets.h))
        text.text = title
        text.font = ZFont.Nice(22.0, style:ZFont.Style.bold)
        text.color = titleColor
        fillBox = true
        imageMargin = ZSize(0.0, 5.0)
    }

    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(name: String) { fatalError("init(name:) has not been implemented") }
    // #end

    func SetColorName(_ col:String) {
        var cimage = ZImage(named:col + "Button.png")
        cimage = cimage!.Make9PatchImage(capInsets:ZRect(insets.w, insets.h, insets.w, insets.h))
        SetImage(cimage)
    }
}



