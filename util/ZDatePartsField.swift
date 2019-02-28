//
//  ZDatePartsField.swift
//  capsulefm
//
//  Created by Tor Langballe on /12/7/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZDatePartsField : ZShapeView {
    var picker: ZDatePartsPicker? = nil
    var edited = false
    var useYear = true
    var optionalYear = false
    var optionalMonth = false
    var optionalDay = false
    var day:Int? = nil
    var month:Int? = nil
    var year:Int? = nil
    var monthChars = 3
    
    init(year:Int? = nil, month:Int? = nil, day:Int? = nil) {
        self.year = year
        self.month = month
        self.day = day
        
        super.init(type:.roundRect, minSize: ZSize(40, 38))
        
        textXMargin = 10
        setTextFromParts()
        
        HandlePressedInPosFunc = { [weak self] (pos) in
            let v1 = ZVStackView(space:2)
            self!.picker = ZDatePartsPicker(useYear:self!.useYear, monthChars:self!.monthChars)
            self!.picker!.optionalYear = self!.optionalYear
            self!.picker!.optionalMonth = self!.optionalMonth
            self!.picker!.optionalDay = self!.optionalDay
            self!.picker!.text = self!.text
            self!.picker!.text.font = self!.picker!.text.font.NewWithSize(22)!
            self!.picker!.monthChars = self!.monthChars
            self!.picker!.Setup()
            self!.picker!.SetValues(self!.year, m:self!.month, d:self!.day)
            
            let confirm = ZConfirmStack() { (result) in
                if result {
                    self!.edited = true
                    self!.year = self!.picker!.year
                    self!.month = self!.picker!.month
                    self!.day = self!.picker!.day
                    self!.setTextFromParts()
                    self!.Expose()
                    self!.valueTarget?.HandleValueChanged(self!)
                }
                ZPopTopView()
            }
            v1.Add(confirm, align:.Center | .HorExpand | .NonProp)
            v1.Add(self!.picker!, align:.Center)
            ZPresentView(v1)
        }
    }
    
    fileprivate func setTextFromParts() {
        var sday = ""
        var smonth = ""
        var syear = ""
        if day != nil {
            sday = "\(day!)" + ZWords.GetDateInsertDaySymbol()
        }
        if month != nil {
            smonth = ZWords.GetMonthFromNumber(month!) + ZWords.GetDateInsertMonthSymbol()
        }
        if useYear && year != nil {
            syear = "\(year!)" + ZWords.GetDateInsertYearSymbol()
        }
        let str = ZStr.ConcatNonEmpty(sep:" ", items:[sday, smonth, syear])
        text.text = str
        Expose()
    }
    
    func HandlePicked(_ year:Int?, month:Int?, day:Int?) {
        valueTarget?.HandleValueChanged(self)
    }
    
    // #swift-only:
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(name: String) { fatalError("init(name:) has not been implemented") }
    // #end
}

