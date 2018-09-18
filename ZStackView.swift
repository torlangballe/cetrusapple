//
//  ZStack.swift
//
//  Created by Tor Langballe on /20/10/15.
//
// #package com.github.torlangballe.CetrusAndroid

import UIKit

class ZStackView: ZContainerView {
    var space = 6.0
    var vertical = false
    
    override init(name:String = "stackview") {
        super.init(name:name)
        //    userInteractionEnabled = false
    }

    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
    
    private func getCellFitSizeInTotal(total:ZSize, cell:ZContainerCell) -> ZSize {
        var tot = total - cell.margin
        if cell.alignment & ZAlignment.HorCenter {
            tot.w -= cell.margin.w
        }
        if cell.alignment & ZAlignment.VertCenter {
            tot.h -= cell.margin.h
        }
        return tot
    }
    
    @discardableResult override func CalculateSize(_ total: ZSize) -> ZSize { // can force size calc without needed result
        var s = ZSize(0, 0)
        for c1 in cells {
            if !c1.collapsed && !c1.free {
                let tot = getCellFitSizeInTotal(total:total, cell:c1)
                var fs = zConvertViewSizeThatFitstToZSize(view:c1.view!, sizeIn:tot)
                var m = c1.margin
                if (c1.alignment & ZAlignment.MarginIsOffset) {
                    m = ZSize(0, 0)
                }
                s[vertical] +=  fs[vertical] + m[vertical]
                s[!vertical] = max(s[!vertical], fs[!vertical] - m[!vertical])
                s[vertical] += space
            }
        }
        s -= margin.size
        if cells.count > 0 {
            s[vertical] -= space
        }
        s[!vertical] = max(s[!vertical], minSize[!vertical])
        return s
    }
    
    private func handleAlign(size:ZSize, inRect:ZRect, a:ZAlignment, cell:ZContainerCell) -> ZRect {
        var vr = inRect.Align(size, align:a, marg:cell.margin, maxSize:cell.maxSize)
        if cell.handleTransition != nil {
            if let r = cell.handleTransition!(size, ZScreen.Orientation(), inRect, vr) {
                vr = r
            }
        }
        return vr
    }
    
    override func ArrangeChildren(onlyChild:ZView? = nil) {
        var incs = 0
        var decs = 0
        var sizes = [UIView: ZSize]()
        var ashrink = ZAlignment.HorShrink
        var aexpand = ZAlignment.HorExpand
        var aless = ZAlignment.Left
        var amore = ZAlignment.Right
        var amid  = ZAlignment.HorCenter | ZAlignment.MarginIsOffset
        
        HandleBeforeLayout()
        
        if(vertical) {
            ashrink = ZAlignment.VertShrink
            aexpand = ZAlignment.VertExpand
            aless = ZAlignment.Top
            amore = ZAlignment.Bottom
            amid  = ZAlignment.VertCenter
        }
        for c2 in cells {
            if !c2.free {
                if c2.collapsed {
                    zRemoveViewFromSuper(c2.view!)
                } else {
                    if (c2.alignment & ashrink) {
                        decs += 1
                    }
                    if (c2.alignment & aexpand) {
                        incs += 1
                    }
                }
            }
            if let cv = c2.view as? ZCustomView {
                cv.HandleBeforeLayout()
            }
        }
        var r = Rect
        r.pos = ZPos() // translate to 0,0 cause children are in parent
        r += margin
        for c1 in cells {
            if c1.free {
                arrangeChild(c1, r:r)
            }
        }
        let cn = r.Center[vertical]
        var cs = CalculateSize(r.size)[vertical]
        cs += margin.size[vertical] // subtracts margin, since we've already indented for that
        let diff = r.size[vertical] - cs
        for c3 in cells {
            if !c3.collapsed && !c3.free {
                let tot = getCellFitSizeInTotal(total:r.size, cell:c3)
                var s = zConvertViewSizeThatFitstToZSize(view:c3.view!, sizeIn:tot)
                if decs > 0 && (c3.alignment & ashrink) && diff != 0.0 {
                    s[vertical] += diff / Double(decs)
                } else if incs > 0 && (c3.alignment & aexpand) && diff != 0.0 {
                    s[vertical] += diff / Double(incs)
                }
                sizes[c3.view!] = s
            }
        }
        var centerDim = 0.0
        var firstCenter = true
        for c4 in cells {
            if !c4.collapsed && !c4.free {
                if (c4.alignment & (amore|aless)) {
                    let a = c4.alignment.Subtracted(ZAlignment.Expand[vertical])
                    let vr = handleAlign(size:sizes[c4.view!]!, inRect:r, a:a, cell:c4)
                    //                ZDebug.Print("alignx:", (c4.view as! ZView).objectName, vr)
                    if onlyChild == nil || onlyChild!.View() == c4.view {
                        zSetViewFrame(c4.view!, frame:vr)
                    }
                    if (c4.alignment & aless) {
                        let m = max(r.Min[vertical], vr.Max[vertical] + space)
                        if vertical {
                            r.SetMinY(m)
                        } else {
                            r.SetMinX(m)
                        }
                    }
                    if (c4.alignment & amore) {
                        let m = min(r.Max[vertical], vr.pos[vertical] - space)
                        if vertical {
                            r.SetMaxY(m)
                        } else {
                            r.SetMaxX(m)
                        }
                    }
                    if let v = c4.view as? ZContainerView {
                        v.ArrangeChildren()
                    } else {
                        //! (c4.view as? ZCustomView)?.HandleAfterLayout()
                    }
                } else {
                    centerDim += sizes[c4.view!]![vertical]
                    if !firstCenter {
                        centerDim += space
                    }
                    firstCenter = false
                }
            }
        }
        if vertical {
            r.SetMinY(max(r.Min.y, cn - centerDim / 2))
        } else {
            r.SetMinX(max(r.Min.x, cn - centerDim / 2))
        }
        if vertical {
            r.SetMaxY(min(r.Max.y, cn + centerDim / 2))
        } else {
            r.SetMaxX(min(r.Max.x, cn + centerDim / 2))
        }
        for c5 in cells {
            if !c5.collapsed && (c5.alignment & amid) && !c5.free { // .reversed()
                let a = ZAlignment(rawValue:(c5.alignment.rawValue & ZBitwiseInvert(amid.rawValue)) | aless.rawValue)
                let vr = handleAlign(size:sizes[c5.view!]!, inRect:r, a:a, cell:c5)
                if onlyChild == nil || onlyChild!.View() == c5.view {
                    zSetViewFrame(c5.view!, frame:vr)
                }
                //                ZDebug.Print("alignm:", (c5.view as! ZView).objectName, vr)
                r.pos[vertical] = vr.Max[vertical] + space
                if let v = c5.view as? ZContainerView {
                    v.ArrangeChildren()
                } else {
                    //!          (c5.view as? ZCustomView)?.HandleAfterLayout()
                }
            }
        }
        //        HandleAfterLayout()
    }
}

func ZHStackView(name:String="ZHStackView", space:Double = 6.0) -> ZStackView {
    let h = ZStackView(name:name)
    h.space = space
    return h
}

func ZVStackView(_ name:String="ZVStackView", space:Double = 6.0) -> ZStackView {
    let v = ZStackView(name:name)
    v.vertical = true
    v.space = space
    return v
}

class ZColumnStack : ZStackView {
    var vstack: ZStackView? = nil
    var max:Int = 0
    
    init(max:Int, horSpace:Double) {
        self.max = max
        super.init(name:"zcolumnstack")
        space = horSpace
        vertical = false
    }

    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
    
    @discardableResult override func Add(_ view: UIView, align:ZAlignment, marg: ZSize = ZSize(), maxSize:ZSize = ZSize(), index:Int = -1, free:Bool = false) -> Int {
        if vstack == nil || vstack!.cells.count == max {
            vstack = ZVStackView(space:space)
            return super.Add(vstack!, align:ZAlignment.Left | ZAlignment.Bottom, marg:ZSize(), maxSize:ZSize(), index:-1, free:false)
        }
        return vstack!.Add(view, align:align, marg:marg, maxSize:maxSize, index:index, free:free) // need all args specified for kotlin super call
    }
}


