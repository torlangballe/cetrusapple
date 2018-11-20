//  ZContainerView.swift
//  Created by Tor Langballe on /23/9/14.

// #package com.github.torlangballe.cetrusandroid

import Foundation

struct ZContainerCell : ZCopy {
    var alignment: ZAlignment
    var margin: ZSize
    var view: ZNativeView? = nil
    var maxSize:ZSize = ZSize(0.0, 0.0)
    var collapsed:Bool = false
    var free:Bool = false
    var handleTransition:((_ size:ZSize, _ layout:ZScreenLayout, _ inRect:ZRect, _ alignRect:ZRect)->ZRect?)? = nil
}

open class ZContainerView: ZCustomView {
    var cells:[ZContainerCell]
    var margin = ZRect()
    var liveArrange = false
    var portraitOnly = true
    
    override init(name: String = "ZContainerView") { // required 
        cells = [ZContainerCell]()
        margin = ZRect()
        super.init(name:name)
        //        backgroundColor = UIColor.redColor()
    }
    
    // #swift-only:
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:)") }
    // #end
    
//    deinit {
//        print("ZContainerView.DeInit()")
//    }
    
    @discardableResult func AddCell(_ cell: ZContainerCell, index:Int? = nil) -> Int {
        if index == -1 {
            cells.append(cell)
            zAddNativeView(cell.view!, toParent: self)
            return cells.count - 1
        } else {
            cells.insert(cell, at:index!)
            zAddNativeView(cell.view!, toParent: self, index: index)
            return index!
        }
    }
    
    @discardableResult open func Add(_ view: ZNativeView, align:ZAlignment, marg: ZSize = ZSize(), maxSize:ZSize = ZSize(), index:Int = -1, free:Bool = false) -> Int {
        return AddCell(ZContainerCell(alignment:align, margin:marg, view:view, maxSize:maxSize, collapsed:false, free:free, handleTransition:nil), index:index)
    }

    func Contains(_ view: ZNativeView) -> Bool {
        for c in cells {
            if c.view == view {
                return true
            }
        }
        return false
    }
    
    override public func CalculateSize(_ total: ZSize) -> ZSize {
        return minSize
    }
    
    func SetAsFullView(useableArea: Bool) {
        ZViewSetRect(self, rect:ZScreen.Main)
        minSize = ZScreen.Main.size
        if !ZIsTVBox() {
            let h = ZScreen.StatusBarHeight
            var r = Rect
            if h > 20 && !ZScreen.HasNotch() {
                r.size.h -= h
                ZViewSetRect(self, rect:r)
            } else if useableArea {
                margin.SetMinY(Double(h))
            }
        }
    }
    
//    func Sort(_ sorter:(_ a:ZContainerCell, _ b:ZContainerCell) -> Bool) {
//        cells.sort(by: sorter)
//        ArrangeChildren()
//        Expose()
//    }
//
    open func ArrangeChildrenAnimated(onlyChild:ZView? = nil) {
        ZAnimation.Do(duration:0.6, animations: { [weak self] () in
            self?.ArrangeChildren(onlyChild:onlyChild)
        })
    }
    
    func arrangeChild(_ c:ZContainerCell, r:ZRect) {
        let ir = r.Expanded(c.margin * -2.0)
        let s = zConvertViewSizeThatFitstToZSize(c.view!, sizeIn:ir.size)
        var rv = r.Align(s, align:c.alignment, marg:c.margin, maxSize:c.maxSize)
        if c.handleTransition != nil {
            if let r = c.handleTransition!(s, ZScreen.Orientation(), r, rv) {
                rv = r
            }
        }
        zSetViewFrame(c.view!, frame:rv)
    }
    
    open func ArrangeChildren(onlyChild:ZView? = nil) {
        HandleBeforeLayout()
        let r = ZRect(size:Rect.size) + margin
        for c in cells {
            (c.view as? ZCustomView)?.HandleBeforeLayout()
        }
        for c in cells {
            if c.alignment != ZAlignment.None {
                if onlyChild == nil || c.view == onlyChild!.View() {
                    arrangeChild(c, r:r)
                }
                if let v = c.view as? ZContainerView {
                    v.ArrangeChildren(onlyChild:onlyChild)
                }
            }
        }
        HandleAfterLayout()
        for c in cells {
            (c.view as? ZCustomView)?.HandleAfterLayout()
        }
    }

    @discardableResult func CollapseChild(_ view:ZView, collapse:Bool = true, arrange:Bool = false) -> Bool {
        if let i = FindCellWithView(view) {
            let changed = (cells[i].collapsed != collapse)
            if changed {
                if collapse {
                    zRemoveNativeViewFromParent(cells[i].view!, detachFromContainer:false)
                } else {
                    zAddNativeView(cells[i].view!, toParent:self)
                }
            }
            cells[i].collapsed = collapse
            if arrange {
                ArrangeChildren()
            }
            return changed
        }
        return false
    }

    @discardableResult func CollapseChildWithName(_ name:String, collapse:Bool = true, arrange:Bool = false) -> Bool {
        if let v = FindViewWithName(name) {
            return CollapseChild(v, collapse:collapse, arrange:arrange)
        }
        return false
    }

    func RangeChildren(subViews:Bool = false, foreach: (ZView)->Bool) {
        for c in cells {
            if let v = c.view as? ZView {
                if !foreach(v) {
                    return
                }
                if subViews {
                    if let cv = v as? ZContainerView {
                        cv.RangeChildren(subViews:subViews, foreach:foreach)
                    }
                }
            }
        }
    }
    
    func FindViewWithName(_ name: String) -> ZView? {
        if let i = FindCellWithName(name) {
            if let v = cells[i].view as? ZView {
                return v
            }
        }
        return nil
    }
    

    @discardableResult func RemoveNamedChild(_ name:String, all:Bool = false) -> Bool {
        for c in cells {
            if let v = c.view as? ZView , v.objectName == name {
                RemoveChild(c.view!)
                if !all {
                    return true
                }
            }
        }
        return false
    }

    func FindViewWithName(_ name: String, recursive:Bool = false) -> ZView? {
        for c in cells {
            if let v = c.view as? ZView {
                if v.objectName == name {
                    return v
                }
                if recursive {
                    if let cv = v as? ZContainerView {
                        let v = cv.FindViewWithName(name)
                        if v != nil {
                            return v
                        }
                    }
                }
            }
        }
        return nil
    }

    func FindCellWithName(_ name: String) -> Int? {
        for (i, c) in cells.enumerated() {
            if let v = c.view as? ZView {
                if v.objectName == name {
                    return i
                }
            }
        }
        return nil
    }

    func FindCellWithView(_ view:ZView) -> Int? {
        for (i, c) in cells.enumerated() {
            if let v = c.view as? ZView {
                if v.View() == view.View() {
                    return i
                }
            }
        }
        return nil
    }

    func RemoveChild(_ subView:ZNativeView) {
        zRemoveNativeViewFromParent(subView, detachFromContainer:false)
        DetachChild(subView)
    }

    func RemoveAllChildren() {
        for c in cells {
            DetachChild(c.view!)
            zRemoveNativeViewFromParent(c.view!, detachFromContainer:false)
        }
    }

    open func HandleRotation() {
        
    }

    func DetachChild(_ subView:ZNativeView) {
        for (i, c) in cells.enumerated() {
            if c.view == subView {
                cells.removeAt(i)
                break
            }
        }
    }
    
    open func HandleBackButton() { // only android has hardware back button...
        
    }
}


