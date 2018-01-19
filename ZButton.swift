//
//  ZButton.swift
//  capsule.fm
//
//  Created by Tor Langballe on /14/12/17.
//  Copyright © 2017 Capsule.fm. All rights reserved.
//

import UIKit

class ZButton : ZShapeView {
    init(title:String, namedImage:String, w:Double, insets:ZSize = ZSize(6, 13), titleColor:ZColor = ZColor.White()) {
        super.init(type:.none, minSize:ZSize(w, 44))
        image = ZImage(named:namedImage)
        image = image!.MakeScaleImage(capInsets:ZRect(insets.w, insets.h, insets.w, insets.h))
        imageMargin = ZSize(0, 0)
        text.text = title
        text.font = ZFont.Nice(22, style:.bold)
        text.color = titleColor
        fillBox = true
        imageMargin = ZSize(0, 5)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(name: String) { fatalError("init(name:) has not been implemented") }
}


