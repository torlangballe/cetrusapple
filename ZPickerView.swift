//
//  ZPickerView.swift
//  Zed
//
//  Created by Tor Langballe on /12/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

protocol ZPickerDelegate {
    func HandlePicked(_ column:Int, row:Int)
}
//
class ZPickerView : UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate, ZView {
    struct Column : ZCopy {
        var name = ""
        var titles = [String]()
        var width: Double = 10
        var wrap = false
        var setRow:Int = 0
        var fontSize:Double = 0
        var alignment:ZAlignment = .None
    }
    var objectName = "ZPickerView"
    var columns: [Column] = [Column]()
    var textAlignment: ZAlignment = .Left
    var height: Double = 216
    var rowHeight: Double = 40
    var pickDelegate: ZPickerDelegate? = nil
    
    init(frame:ZRect) {
        super.init(frame:frame.GetCGRect())
        delegate = self
        dataSource = self
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func View() -> UIView {
        return self
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let r = row % columns[component].titles.count
        columns[component].setRow = r
        if pickDelegate != nil {
            pickDelegate?.HandlePicked(component, row:r)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return columns.count
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return columns[component].titles.count
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return CGFloat(columns[component].width)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(rowHeight)
    }
    func pickerView(_ pickerView: UIPickerView, accessibilityLabelForComponent component:Int) -> String? {
        return columns[component].name
    }
    func pickerView(_ pickerView: UIPickerView, accessibilityHintForComponent component:Int) -> String? {
        return ""
    }
    func Reload() {
        reloadAllComponents()
    }
    func Set(_ column:Int, row:Int, animated:Bool = false) {
        columns[column].setRow = row
        selectRow(row, inComponent:column, animated:animated)
    }
    
    func SetWithTitle(_ title:String, column:Int = 0, animated:Bool) {
        if let i = columns[column].titles.index(of: title) {
            Set(column, row:i, animated:animated)
        }
    }
}

class ZLabelPickerView : ZPickerView {
    var text = ZTextDraw()
    
    @objc func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        let attributes = getText(component).MakeAttributes()
        let astring = NSAttributedString(string:columns[component].titles[row], attributes:attributes)
        if pickerLabel == nil {
            pickerLabel = UILabel()
        } 
        pickerLabel!.attributedText = astring
        return pickerLabel!
    }

    override init(frame:ZRect) {
        super.init(frame:frame)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    @discardableResult override func sizeThatFits(_ size: CGSize) -> CGSize {
        var wAll = 0.0
        rowHeight = 0
        
        for (i, c) in columns.enumerated() {
            var t = getText(i)
            var s = ZSize()
            for str in c.titles {
                t.text = str
                s.Maximize(t.GetBounds().size)
                rowHeight = max(rowHeight, s.h)
            }
            columns[i].width = s.w * 1.05
            wAll += s.w
        }
        rowHeight *= 1
        wAll += Double(columns.count - 1) * 4;
        let s = ZSize(max(wAll + 40, 216), height)
        return s.GetCGSize()
    }

    
    func Refresh() {
        sizeThatFits(frame.size)
    }
    
    func getText(_ component:Int) -> ZTextDraw {
        var t = text
        let size = columns[component].fontSize
        if size != 0 {
            t.font = t.font.withSize(CGFloat(size))
        }
        let align = columns[component].alignment
        if align != .None {
            t.alignment = align
        }
        return t
    }
}

