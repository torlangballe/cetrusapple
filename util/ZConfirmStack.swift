//
//  ZConfirmStack.swift
//
//  Created by Tor Langballe on /26/6/16.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

class ZConfirmStack : ZStackView {
    var done:((_ result:Bool)->Void)? = nil
    
    @discardableResult static func PushViewWithTitleBar(_ view:ZView, title:String, deleteOld:Bool = false) -> ZStackView {
        let v1 = ZVStackView(space:0.0)
        if let cv = view as? ZContainerView {
            v1.singleOrientation = cv.singleOrientation
        }
        let titleBar = ZTitleBar(text:title, closeType:ZTitleBar.CloseButtons.cross)
        v1.Add(titleBar, align:ZAlignment.Top | ZAlignment.HorCenter | ZAlignment.HorExpand | ZAlignment.NonProp)
        v1.Add(view.View(), align:ZAlignment.HorCenter | ZAlignment.Bottom | ZAlignment.Expand | ZAlignment.NonProp)
        ZPresentView(v1, deleteOld:deleteOld)
        
        return v1
    }

    init(useOk:Bool = true, strokecolor:ZColor = ZColor.White(), done:((_ result:Bool)->Void)? = nil) {
        super.init(name:"confirm")
        self.done = done
        margin = ZRect(30.0, 0.0, -30.0, 0.0)
        
        var ca = ZAlignment.HorCenter
        if useOk {
            let set = createShape("check", strokeColor:strokecolor, align:ZAlignment.Right)
            set.accessibilityLabel = ZWords.GetSet()
            ca = ZAlignment.Left
        }
        let cancel = createShape("cross", strokeColor:strokecolor, align:ca)
        cancel.accessibilityLabel = ZWords.GetCancel()
    }
    
    // #swift-only:
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
    
    fileprivate func createShape(_ name:String, strokeColor:ZColor, align:ZAlignment) -> ZShapeView {
        let shape = ZShapeView(type:ZShapeView.ShapeType.circle, minSize:ZSize(64.0, 64.0))
        shape.image = ZImage(named:name + ".png")
        shape.objectName = name
        shape.strokeColor = strokeColor
        shape.strokeWidth = 2.0
        shape.HandlePressedInPosFunc = { [weak self] (pos) in
            if shape.objectName == "check" {
                self?.done?(true)
            } else if shape.objectName == "cross" {
                self?.done?(false)
                if self!.FindCellWithName("check") == nil {
                    ZPopTopView()
                }
            }
        }
//        AddTarget(self, forEventType:ZControlEventType.pressed)
        Add(shape, align:align | ZAlignment.VertCenter)
        
        return shape
    }
    
    func WrapForPushWithView(_ view:ZView) -> ZCustomView {
        let v1 = ZVStackView(space:40.0)
        v1.Add(self, align:ZAlignment.Center | ZAlignment.HorExpand | ZAlignment.NonProp)
        v1.Add(view.View(), align:ZAlignment.Center)
        
        return v1
    }
}

