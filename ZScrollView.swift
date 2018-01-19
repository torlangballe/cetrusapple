//
//  ZScrollView.swift
//  Zed
//
//  Created by Tor Langballe on /13/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZScrollView : UIScrollView, ZView, UIScrollViewDelegate { // Add single child. Stack or something
    var objectName = "scrollview"
    var child: ZContainerView? = nil
    var margin = ZRect()
    
    func View() -> UIView {
        return self
    }
    
    func SetContentOffset(_ offset:ZPos, animated:Bool = true) {
        setContentOffset(offset.GetCGPoint(), animated:animated)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width:10, height:10)
    }
    
    override func layoutSubviews() {
        if child != nil {
            let s = ZSize(Float(frame.size.width), 3000)
            var size = ZSize(child!.View().sizeThatFits(s.GetCGSize()))
            //            maximize(&size.w, s.w)
            size.w = s.w
            //            minimize(&size.w, ZScreen.Main.size.w)
            //            frame.size.width = CGFloat(size.w)
            var r = ZRect(size:size)
            r += margin
            child!.View().frame = r.GetCGRect()
            self.contentSize = size.GetCGSize()
            child?.ArrangeChildren()
            self.delegate = self
        }
    }
    
    func ArrangeChildren() {
        layoutSubviews()
    }
    
    func SetChild(_ view:ZContainerView) {
        if child != nil {
            child?.RemoveFromParent()
        }
        child = view
        self.addSubview(view.View())
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.endEditing(true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
        super.touchesBegan(touches, with:event)
    }

    static func ScrollViewToMakeItVisible(_ view:ZView) {
        var s:UIView? = view.View()
        while s != nil {
            s = s!.superview
            if s != nil {
                if let sv = s! as? ZScrollView {
                    if Double(sv.frame.size.height) - sv.margin.size.h < Double(sv.contentSize.height) {
                        let y = Float(view.View().convert(view.View().bounds, to:sv.View()).origin.y)
                        sv.SetContentOffset(ZPos(0, y - 40))
                    }
                    break
                }
            }
        }

    }
}
