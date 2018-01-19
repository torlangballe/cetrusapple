//
//  ZHorDivider.swift
//  capsulefm
//
//  Created by Tor Langballe on /11/7/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZHorDivider: ZCustomView {
    override init(name:String = "hordiv") {
        super.init(name:name)
        SetFGColor(ZColor(white:1, a:0.3))
        minSize = ZSize(50, 1)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        canvas.SetColor(foregroundColor)
        canvas.FillPath(ZPath(rect:rect))
    }
}




