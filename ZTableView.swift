//
//  ZTableView.swift
//  Zed
//
//  Created by Tor Langballe on /4/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

protocol ZTableViewDelegate : class {
    func TableViewGetNumberOfRowsInSection(_ section:Int) -> Int
    func TableViewGetNumberOfSections() -> Int
    func TableViewGetHeightOfItem(_ index: ZTableView.Index)  -> Double
    func TableViewSetupCell(_ cellSize:ZSize, index:ZTableView.Index) -> ZCustomView?
    func HandleTableDelete()
    func HandleRowSelected(_ index:ZTableView.Index)
    func GetAccessibilityForCell(_ index:ZTableView.Index, prefix:String) -> [ZAccessibilty]
}

typealias ZTableViewRowAnimation = UITableViewRowAnimation

class ZTableView : UITableView, ZView, UITableViewDelegate, UITableViewDataSource {
    var first = true
    var objectName = "ZTableView"
    var tableRowBackgroundColor = ZColor.Black()
    var scrolling = false
    var drawHandler:((_ rect: ZRect, _ canvas: ZCanvas)->Void)!
    var margins = ZSize(0, 0)
    
    func View() -> UIView { return self }
    
    struct Index {
        var row = 0
        var section = 0
        init(row:Int = 0, section:Int = 0) {
            self.row = row
            self.section = section
        }
        init(path:IndexPath) {
            row = (path as NSIndexPath).row
            section = (path as NSIndexPath).section
        }
    };
    
    var selection = Index()
    weak var owner: ZTableViewDelegate? = nil
    var selectable = true
    var deleteHandler: (()->Void)? = nil
    var selectedColor = ZColor()
    
    init(grouped:Bool = false) {
        super.init(frame:CGRect(x:0, y:0, width:10, height:10), style:(grouped ? .grouped : .plain))
        delegate = self
        selection.row = -1;
        dataSource = self
        sectionFooterHeight = 3;
        backgroundView = nil
        separatorStyle = UITableViewCellSeparatorStyle.none
        //        self.registerClass(UallITableViewCell.self, forCellReuseIdentifier:"ZTableView")
        allowsSelection = true // selectable
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        if first {
            allowsSelection = true // selectable
            if selection.row != -1 {
                Select(selection.row, section:selection.section);
            }
            contentInset = UIEdgeInsetsMake(CGFloat(margins.h), CGFloat(margins.w), CGFloat(margins.h), CGFloat(margins.w))
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
        reloadRows(at: indexPathsForVisibleRows ?? [], with:animate ? UITableViewRowAnimation.automatic : UITableViewRowAnimation.none)
    }
    
    func ReloadData(animate:Bool = false) {
        if animate {
            self.reloadSections([0], with:UITableViewRowAnimation.fade)
        } else {
            reloadData()
        }
        //        let range = NSMakeRange(0, numberOfSections)
        //        let indexSet = NSIndexSet(indexesInRange:range)
        //        reloadSections(indexSet, withRowAnimation:UITableViewRowAnimation.Automatic)
    }

    func MoveRow(fromIndex:Int, toIndex:Int) {
        let from = makeIndexPathFromIndex(Index(row:fromIndex, section:0))
        let to = makeIndexPathFromIndex(Index(row:toIndex, section:0))
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
        let indexpath = makeIndexPathFromIndex(Index(row:index, section:0))
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
    
    static func GetIndexFromRowView(_ view:ZView) -> Int? {
        var p:UIView? = view.View()
        while p != nil {
            if let v = p as? ZTableView {
                return v.GetIndexFromRowView(view)
            }
            p = p?.superview
        }
        return nil
    }
    
    func Select(_ row:Int, section:Int = 0) {
        let oldSelection = selection
        selection = Index(row:row, section:section)
        if selectable {
            if row == -1 {
                if oldSelection.row != -1 {
                    deselectRow(at: makeIndexPathFromIndex(oldSelection), animated:true)
                }
            } else {
                selectRow(at: makeIndexPathFromIndex(selection), animated:true, scrollPosition:UITableViewScrollPosition.bottom) // none means least movement
            }
        }
    }
    
    
    func DeleteChildRow(index:Int, animation:ZTableViewRowAnimation = .fade) { // call this after removing data
        let ipath = makeIndexPathFromIndex(Index(row:index, section:0))
        self.deleteRows(at:[ipath], with: .fade)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = ZTableView.Index(path:indexPath)
        owner!.HandleRowSelected(index)
        selection = index
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = ZTableView.Index(path:indexPath)
        return CGFloat(owner!.TableViewGetHeightOfItem(index))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return owner!.TableViewGetNumberOfSections()
    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        let c = owner!.TableViewGetNumberOfRowsInSection(section)
        return c
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let cell : UITableViewCell = self.dequeueReusableCellWithIdentifier("ZTableView", forIndexPath:indexPath) as UITableViewCell
        let cell = UITableViewCell()
        cell.isEditing = true
        let index = ZTableView.Index(path:indexPath)
        var r = ZRect(size:ZSize(Rect.size.w, owner!.TableViewGetHeightOfItem(index)))
        r = r.Expanded(ZSize(-margins.w * 2, 0))
        cell.frame = r.GetCGRect()
        cell.backgroundColor = UIColor.clear
        
        let customView = owner!.TableViewSetupCell(ZSize(cell.frame.size), index:index)
        customView?.frame = cell.frame
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
    
    fileprivate func makeIndexPathFromIndex(_ index:ZTableView.Index) -> IndexPath {
        
        let indexes:[Int] = [ index.section, index.row]
        
        return (NSIndexPath(indexes:indexes, length:2) as IndexPath)
    }
}

extension ZTableViewDelegate {
    func TableViewGetNumberOfSections() -> Int { return 1 }
    //    func TableViewGetHeightOfItem(index: ZTableView.Index) -> Double { return 52 }
    func HandleTableDelete() { }
    func HandleRowSelected(_ index:ZTableView.Index) { }
    func GetAccessibilityForCell(_ index:ZTableView.Index, prefix:String) -> [ZAccessibilty] { return [] }
}

private func exposeAll(_ view:UIView) {
    view.setNeedsDisplay()
    for s in view.subviews {
        exposeAll(s)
    }
}
