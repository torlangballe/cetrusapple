//
//  ZTableView.swift
//
//  Created by Tor Langballe on /4/12/15.
//
// #package com.github.torlangballe.cetrusandroid

import UIKit

class zUITableViewCell : UITableViewCell {
    //    deinit {
    //        print("UITableViewCell deinit")
    //    }
}

protocol ZTableViewDelegate : class {
    func TableViewGetRowCount() -> Int
    func TableViewGetHeightOfItem(_ index: Int)  -> Double
    func TableViewSetupCell(_ cellSize:ZSize, index: Int) -> ZCustomView?
    func HandleRowSelected(_ index: Int)
//    func UpdateRow(index: Int)
    func GetAccessibilityForCell(_ index: Int, prefix:String) -> [ZAccessibilty]
}

typealias ZTableViewRowAnimation = UITableView.RowAnimation

class ZTableView : UITableView, ZView, UITableViewDelegate, UITableViewDataSource {
    var first = true
    var objectName = "ZTableView"
    var tableRowBackgroundColor = ZColor.Black()
    var scrolling = false
    var drawHandler:((_ rect: ZRect, _ canvas: ZCanvas)->Void)? = nil
    var margins = ZSize(0, 0)
    var spacing = 0.0
    var focusedRow:Int? = nil
    
    func View() -> UIView { return self }
    
    var selectionIndex = 0
    weak var owner: ZTableViewDelegate? = nil
    var selectable = true
    var deleteHandler: (()->Void)? = nil
    var selectedColor = ZColor()
    
    init() {
        super.init(frame:CGRect(x:0, y:0, width:10, height:10), style:.plain)
        delegate = self
        selectionIndex = -1
        dataSource = self
//        sectionFooterHeight = 3
        backgroundView = nil
        #if os(iOS)
      separatorStyle = UITableViewCell.SeparatorStyle.none
        #endif
        //        self.registerClass(UallITableViewCell.self, forCellReuseIdentifier:"ZTableView")
        allowsSelection = true // selectable
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
//        let tvOsInset:CGFloat = ZIsTVBox() ? 174 : 0
//        let tvOsInset:CGFloat = ZIsTVBox() ? 87 : 0
        if first {
            allowsSelection = true // selectable
            if selectionIndex != -1 {
                Select(selectionIndex);
            }
  //        contentInset = UIEdgeInsets(top: CGFloat(margins.h), left: -tvOsInset, bottom: CGFloat(margins.h), right: tvOsInset)
            first = false
        }
        super.layoutSubviews()
    }
    
    override func draw(_ rect: CGRect) {
        drawHandler?(ZRect(rect), ZCanvas(context: UIGraphicsGetCurrentContext()!))
    }


    func ExposeRows() {
        for i in indexPathsForVisibleRows ?? [] {
            if let c = self.cellForRow(at: i) {
                exposeAll(c.contentView)
            }
        }
    }
    
    func UpdateVisibleRows(_ animate:Bool = true) {
      reloadRows(at: indexPathsForVisibleRows ?? [], with:animate ? UITableView.RowAnimation.automatic : UITableView.RowAnimation.none)
    }
    
    func ScrollToMakeRowVisible(_ row:Int, animated:Bool = true) {
        let path = makeIndexPathFromIndex(row)
        scrollToRow(at: path, at:.none, animated:animated)
    }
    
    func UpdateRow(row: Int) {
        reloadRows(at:[makeIndexPathFromIndex(row)], with:UITableView.RowAnimation.none)
    }
    
    func ReloadData(animate:Bool = false) {
        if animate {
          self.reloadSections([0], with:UITableView.RowAnimation.fade)
        } else {
            reloadData()
        }
    }
    
    func MoveRow(fromIndex:Int, toIndex:Int) {
        let from = makeIndexPathFromIndex(fromIndex)
        let to = makeIndexPathFromIndex(toIndex)
        self.moveRow(at:from, to:to)
    }
    
    private func getZViewChild(_ v:UIView) -> ZView? {
        for c in v.subviews {
            if let z = c as? ZView {
                return z
            }
        }
        for c in v.subviews {
            if let z = getZViewChild(c) {
                return z
            }
        }
        return nil
    }
    
    func GetRowViewFromIndex(_ index:Int) -> ZView? {
        let indexpath = makeIndexPathFromIndex(index)
        if let c = self.cellForRow(at: indexpath) {
            return getZViewChild(c)
        }
        return nil
    }
    
    func GetIndexFromRowView(_ view:ZView) -> Int? {
        var v = view.View()
        repeat {
            v = v.superview!
        } while !(v is UITableViewCell)
        if let path = self.indexPath(for:v as! UITableViewCell) {
            return path.row
        }
        return nil
    }
    
    static func GetParentTableViewFromRow(_ child:ZContainerView) -> ZTableView {
        var p:UIView? = child.View()
        while p != nil {
            if let v = p as? ZTableView {
                return v
            }
            p = p?.superview
        }
        fatalError("ZTableView.GetParentTableViewFromRow failed!")
    }
    
    static func GetIndexFromRowView(_ view:ZContainerView) -> Int {
        let v = GetParentTableViewFromRow(view)
        return v.GetIndexFromRowView(view) ?? -1 // -1 should never happen
    }
    
    func Select(_ row:Int) {
        let oldSelection = selectionIndex
        selectionIndex = row
        if selectable {
            if row == -1 {
                if oldSelection != -1 {
                    deselectRow(at: makeIndexPathFromIndex(oldSelection), animated:true)
                }
            } else {
              selectRow(at: makeIndexPathFromIndex(selectionIndex), animated:true, scrollPosition:UITableView.ScrollPosition.none) // none means least movement
            }
        }
    }
    
    func DeleteChildRow(index:Int, animation:ZTableViewRowAnimation = .fade) { // call this after removing data
        let ipath = makeIndexPathFromIndex(index)
        self.deleteRows(at:[ipath], with: .left)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrolling = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrolling = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrolling = false
    }

    func IsFocused(rowView:ZCustomView) -> Bool {
        if focusedRow != nil, let row = GetIndexFromRowView(rowView) {
            return row == focusedRow!
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let next = context.nextFocusedIndexPath {
            focusedRow = next.row
            if let view = GetRowViewFromIndex(next.row) {
                view.Expose()
            }
        } else {
            focusedRow = nil
        }
        if let prev = context.previouslyFocusedIndexPath {
            if let view = GetRowViewFromIndex(prev.row) {
                view.Expose()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = pathToRow(indexPath)
        owner!.HandleRowSelected(index)
        selectionIndex = index
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = pathToRow(indexPath)
        return CGFloat(owner!.TableViewGetHeightOfItem(index))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        let c = owner!.TableViewGetRowCount()
        return c
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let cell : UITableViewCell = self.dequeueReusableCellWithIdentifier("ZTableView", forIndexPath:indexPath) as UITableViewCell
        let cell = zUITableViewCell()
        cell.isEditing = true
        let index = pathToRow(indexPath)
        var r = ZRect(size:ZSize(Rect.size.w, owner!.TableViewGetHeightOfItem(index)))
        var m = margins.w
        if ZIsTVBox() {
            m = 87
        }
        r = r.Expanded(ZSize(-m, 0))
        if ZIsTVBox() {
            cell.focusStyle = UITableViewCell.FocusStyle.custom
        }
        cell.frame = r.GetCGRect()
        cell.backgroundColor = UIColor.clear
        let s = ZSize(cell.frame.size)
        let customView = owner!.TableViewSetupCell(s, index:index)
        customView?.frame = ZRect(size:s).GetCGRect()
        if !ZIsTVBox() {
            customView!.minSize.h -= spacing
        }
        customView?.frame.size.height = CGFloat(customView!.minSize.h)
        if let cv = customView as? ZContainerView {
            cv.ArrangeChildren()
        }
        cell.isUserInteractionEnabled = true //cell.Usable
        if selectable {
            if !selectedColor.undefined {
                let bgColorView = UIView()
                bgColorView.backgroundColor = selectedColor.rawColor
                cell.selectedBackgroundView = bgColorView
            } else {
                cell.selectedBackgroundView = UIView()
            }
        }
        if customView != nil {
            cell.contentView.addSubview(customView!)
            cell.isOpaque = customView!.isOpaque
            cell.backgroundColor = customView!.backgroundColor
        }
        if cell.backgroundColor != nil && cell.backgroundView != nil && ZColor(color:cell.backgroundColor!).Opacity == 0.0 {
            cell.backgroundView!.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.clear
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay willDisplayCell:UITableViewCell, forRowAt forRowAtIndexPath:IndexPath) {
        //        ZDebug.Print("willDisplayCell:", forRowAtIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    fileprivate func makeIndexPathFromIndex(_ index:Int) -> IndexPath {
        let indexes:[Int] = [ 0, index]
        return (NSIndexPath(indexes:indexes, length:2) as IndexPath)
    }
}

extension ZTableViewDelegate {
    //    func TableViewGetHeightOfItem(index: Int) -> Double { return 52 }
    func HandleRowSelected(_ index:Int) { }
    func GetAccessibilityForCell(_ index:Int, prefix:String) -> [ZAccessibilty] { return [] }
//    func UpdateRow(index: Int) { }
}

private func exposeAll(_ view:UIView) {
    view.setNeedsDisplay()
    for s in view.subviews {
        exposeAll(s)
    }
}

func pathToRow(_ path:IndexPath) -> Int {
    return (path as NSIndexPath).row
}


