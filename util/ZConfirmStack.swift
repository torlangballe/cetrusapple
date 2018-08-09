//
//  ZConfirmStack.swift
//  capsulefm
//
//  Created by Tor Langballe on /26/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZConfirmStack : ZStackView {
    let done:((_ result:Bool)->Void)?
    
    init(useOk:Bool = true, strokecolor:ZColor = ZColor.White(), done:((_ result:Bool)->Void)? = nil) {
        self.done = done
        super.init(name:"confirm")
        margin = ZRect(30, 0, -30, 0)
        
        var ca = ZAlignment.HorCenter
        if useOk {
            let set = createShape("check", strokeColor:strokecolor, align:.Right)
            set.accessibilityLabel = ZLocale.GetSet()
            ca = .Left
        }
        let cancel = createShape("cross", strokeColor:strokecolor, align:ca)
        cancel.accessibilityLabel = ZLocale.GetCancel()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    fileprivate func createShape(_ name:String, strokeColor:ZColor, align:ZAlignment) -> ZShapeView {
        let shape = ZShapeView(type:.circle, minSize:ZSize(64, 64))
        shape.image = ZImage(named:name + ".png")
        shape.objectName = name
        shape.strokeColor = strokeColor
        shape.strokeWidth = 2
        shape.AddTarget(self, forEventType:.pressed)
        Add(shape, align:align | .VertCenter)
        
        return shape
    }
    
    override func HandlePressed(_ sender: ZView, pos: ZPos) {
        if sender.objectName == "check" {
            done?(true)
        } else if sender.objectName == "cross" {
            done?(false)
            if FindCellWithName("check") == nil {
                ZPopTopView()
            }
        }
    }
    
    func WrapForPushWithView(_ view:ZView) -> ZCustomView {
        let v1 = ZVStackView(space:40)
        v1.Add(self, align:.Center | .HorExpand | .NonProp)
        v1.Add(view.View(), align:.Center)
        
        return v1
    }
    
    @discardableResult static func PushViewWithTitleBar(_ view:ZView, title:String) -> ZStackView {
        let v1 = ZVStackView(space:0)
        if let cv = view as? ZContainerView {
            v1.portraitOnly = cv.portraitOnly
        }
        let titleBar = ZTitleBar(text:title, closeType:.cross)
        v1.Add(titleBar, align:.Top | .HorCenter | .HorExpand | .NonProp)
        v1.Add(view.View(), align:.HorCenter | .Bottom | .Expand | .NonProp)
        ZPresentView(v1)
        
        return v1
    }
}

