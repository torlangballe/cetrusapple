//
//  ZLabelingStack.swift
//
//  Created by Tor Langballe on 15/02/2019.
//

// #package com.github.torlangballe.cetrusandroid


class ZLabelingStack : ZStackView {
    init(view:ZView, text:String, color:ZColor = ZColor.White(), font:ZFont? = nil) {
        super.init(name: "zlabelstack:" + text)
        space = 4.0
        Add(view.View(), align:ZAlignment.Left | ZAlignment.VertCenter)
        let label = ZLabel(text: text, font: font, color: color)
        Add(label, align:ZAlignment.Left | ZAlignment.VertCenter)
    }

    // #swift-only:
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
}
