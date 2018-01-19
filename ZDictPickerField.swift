//
//  ZDIctPicker.swift
//  capsulefm
//
//  Created by Tor Langballe on /26/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZDictPickerField : ZShapeView {
    var dict: [String:AnyObject]
    var value: AnyObject? = nil
    var edited = false
    var handleValueChanged:((_ key:String)->Void)? = nil
    var selectedKey = ""
    var popupText = ZText()
    
    init(dict:[String:AnyObject], selectedKey:String) {
        
        self.dict = dict
        self.selectedKey = selectedKey
        super.init(type:.roundRect, minSize: ZSize(40, 38))
      
        value = dict[selectedKey]
        text.text = value as? String ?? selectedKey
        text.font = ZFont.Nice(22, style:.bold)
        text.color = ZColor.White()
        
        popupText = text
        
        AddTarget(self, forEventType:.pressed)
        
        HandlePressedInPosFunc = { [weak self] (pos) in
            ZDictPickerField.Pick(dict, selectedKey:selectedKey, textInfo:self!.popupText) { (key, val) in
                if key != nil {
                    self!.selectedKey = key!
                    self!.edited = true
                    self!.value = val!
                    self!.valueTarget?.HandleValueChanged(self!)
                    self!.text.text = self!.selectedKey
                    self!.handleValueChanged?(self!.selectedKey)
                    self!.Expose()
                }
            }
        }
    }

    static func Pick(_ dict:[String:AnyObject], selectedKey:String = "", textInfo:ZText, got:@escaping (_ key:String?, _ val:AnyObject?)->Void) {
        let v1 = ZVStackView(space:2)
        let picker = ZLabelPickerView(frame:ZRect(0, 0, 200, 216))
        picker.height = 400
        picker.text = textInfo
        picker.text.font = picker.text.font.NewWithSize(24)!
        var column = ZPickerView.Column()
        let sorted = dict.keys.sorted(by: {$0 < $1})
        column.titles = sorted 
        picker.columns.append(column)
        picker.Refresh()
        picker.SetWithTitle(selectedKey, animated:false)
        let confirm = ZConfirmStack() { (result) in
            if result {
                let i = picker.columns[0].setRow
                let pickedKey = picker.columns[0].titles[i]
                got(pickedKey, dict[pickedKey])
            } else {
                got(nil, nil)
            }
            ZPopTopView()
        }
        v1.Add(confirm, align:.Center | .HorExpand | .NonProp)
        v1.Add(picker, align:.Center)
        ZPresentView(v1)
    }
    
    func Update() {
        text.text = selectedKey
        Expose()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    required init(name: String) { fatalError("init(name:) has not been implemented") }
}

