//
//  ZHelp.swift
//  capsule.fm
//
//  Created by Tor Langballe on /7/2/18.
//  Copyright © 2018 Capsule.fm. All rights reserved.
//

import UIKit

class ZHelpNote {
    static var font = ZFont.Nice(18)
    static var textColor = ZColor.White()
    
    static func Add(text:String, to:ZContainerView, close:Bool = true, key:String, align:ZAlignment, marg:ZSize = ZSize(6, 6), bgcol:ZColor = ZColor(), count:Int? = nil) {
        let v = ZKeyValueStore.IncrementInt(key)
        if count != nil && v <= count! || v <= 1 {
            let stack = ZHStackView(space:8)
            to.Add(stack, align:align, marg:marg)
            
            let label = ZLabel(text:text, lines:0, font:font, align:.Center, color:textColor)
            label.maxWidth = 100
            stack.Add(label, align:.Left | .VertCenter | .HorExpand | .NonProp)
            
            if close {
                let close = ZImageView(namedImage:"zcross.small")
                stack.Add(close, align:.Left | .Top)
                close.HandlePressedInPosFunc = { [weak to] pos in
                    ZKeyValueStore.SetInt(count != nil ? count! : 1, key:key)
                    to?.RemoveChild(stack)
                }
            }
            if !bgcol.undefined {
                stack.SetBackgroundColor(bgcol)
                stack.SetCornerRadius(10)
            }
        }
    }
}
