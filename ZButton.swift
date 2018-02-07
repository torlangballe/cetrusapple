//
//  ZButton.swift
//  capsule.fm
//
//  Created by Tor Langballe on /14/12/17.
//  Copyright © 2017 Capsule.fm. All rights reserved.
//

import UIKit

class ZButton : ZShapeView {
    var insets:ZSize
    
    init(title:String, namedImage:String, w:Double, insets:ZSize = ZSize(6, 13), titleColor:ZColor = ZColor.White()) {
        self.insets = insets
        super.init(type:.none, minSize:ZSize(w, 44))
        image = ZImage(named:namedImage)
        image = image!.MakeScaleImage(capInsets:ZRect(insets.w, insets.h, insets.w, insets.h))
        text.text = title
        text.font = ZFont.Nice(22, style:.bold)
        text.color = titleColor
        fillBox = true
        imageMargin = ZSize(0, 5)
    }

    convenience init(title:String, color:ZColor, w:Double, insets:ZSize = ZSize(6, 13), titleColor:ZColor = ZColor.White()) {
        let name = getColorFilename(color)
        self.init(title:title, namedImage:name, w:w, insets:insets, titleColor:titleColor)
    }

    func SetButtonColor(_ color:ZColor) {
        let name = getColorFilename(color)
        if var im = ZImage(named:name) {
            im = im.MakeScaleImage(capInsets:ZRect(insets.w, insets.h, insets.w, insets.h))
            SetImage(im)
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(name: String) { fatalError("init(name:) has not been implemented") }
}

private func getColorFilename(_ color:ZColor) -> String {
    var str = ""
    switch color {
    case ZColor.Red():
        str = "red"
    case ZColor.Green():
        str = "green"
    default:
        str = "gray"
    }
    return str + "Button.png"
}


