//  zUIContainerView.swift
//  Zed
//  Created by Tor Langballe on /23/9/14.

import UIKit

class ZContainerView: ZCustomView {
    struct Cell {
        var alignment: ZAlignment
        var margin: ZSize
        var view: UIView
        var maxSize = ZSize(0, 0)
        var collapsed = false
        var free = false
        var handleTransition:((_ size:ZSize, _ layout:ZScreen.Layout, _ inRect:ZRect, _ alignRect:ZRect)->ZRect?)? = nil
    }
    var cells:[Cell]
    var margin = ZRect()
    var liveArrange = false
    var portraitOnly = false
    
    override init(name: String = "ZContainerView") { // required 
        cells = [Cell]()
        margin = ZRect()
        super.init(name:name)
        //        backgroundColor = UIColor.redColor()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
//    deinit {
//        print("ZContainerView.DeInit()")
//    }
    
    func AddCell(_ cell: Cell, index:Int = -1) {
        if index == -1 {
            cells.append(cell)
            self.addSubview(cell.view)
        } else {
            cells.insert(cell, at:index)
            insertSubview(cell.view, at:index)
        }
    }
    
    func Add(_ view: UIView, align:ZAlignment, marg: ZSize = ZSize(), maxSize:ZSize = ZSize(), index:Int = -1, free:Bool = false, handler:((_ size:ZSize, _ screenLayout:ZScreen.Layout, _ inRect:ZRect, _ alignRect:ZRect)->ZRect?)? = nil) {
        AddCell(Cell(alignment:align, margin:marg, view:view, maxSize:maxSize, collapsed:false, free:free, handleTransition:handler), index:index)
    }

    func Contains(_ view: UIView) -> Bool {
        for c in cells {
            if c.view == view {
                return true
            }
        }
        return false
    }
    
    override func CalculateSize(_ total: ZSize) -> ZSize {
        return minSize
    }
    
    func SetAsFullView(useableArea: Bool) {
        frame = UIScreen.main.bounds
        let h = UIApplication.shared.statusBarFrame.size.height
        if h > 20 && !ZScreen.HasNotch() {
            frame.size.height -= h
        } else if useableArea {
            margin.Min.y = Double(h)
        }
    }
    
    func Sort(_ sorter:(_ a:Cell, _ b:Cell) -> Bool) {
        cells.sort(by: sorter)
        ArrangeChildren()
        Expose()
    }
    
    func ArrangeChildrenAnimated(onlyChild:ZView? = nil) {
        ZAnimation.Do(duration:0.6, animations: { () in
            self.ArrangeChildren(onlyChild:onlyChild)
        })
    }
    
    func arrangeChild(_ c:Cell, r:ZRect) {
        let ir = r.Expanded(c.margin * -2.0)
        let s = ZSize(c.view.sizeThatFits(ir.GetCGRect().size))
        var rv = r.Align(s, align:c.alignment, marg:c.margin, maxSize:c.maxSize)
        if c.handleTransition != nil {
            if let r = c.handleTransition!(s, ZScreen.Orientation(), r, rv) {
                rv = r
            }
        }
        c.view.frame = rv.GetCGRect()
    }
    
    func ArrangeChildren(onlyChild:ZView? = nil) {
        HandleBeforeLayout()
        let r = ZRect(size:Rect.size) + margin
        for c in cells {
            (c.view as? ZCustomView)?.HandleBeforeLayout()
        }
        for c in cells where c.alignment != .None {
            if onlyChild == nil || c.view == onlyChild!.View() {
                arrangeChild(c, r:r)
            }
            if let v = c.view as? ZContainerView {
                v.ArrangeChildren(onlyChild:onlyChild)
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
                    cells[i].view.removeFromSuperview()
                } else {
                    addSubview(cells[i].view)
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

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if liveArrange {
            ArrangeChildren()
        }
    }
    
    /*
    override func willRemoveSubview(subview:UIView) {
        super.willRemoveSubview(subview)
        cells = cells.filter({$0.view != subview})
        if liveArrange {
            ArrangeChildren()
        }
    }
    */
    
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
                RemoveChild(c.view)
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

    func RemoveChild(_ subView:UIView) {
        subView.removeFromSuperview()
        DetachChild(subView)
    }

    func RemoveAllChildren() {
        for c in cells {
            DetachChild(c.view)
            c.view.removeFromSuperview()
        }
    }

    func DetachChild(_ subView:UIView) {
        for (i, c) in cells.enumerated() {
            if c.view == subView {
                cells.remove(at: i)
                break
            }
        }
    }
}


