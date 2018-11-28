//
//  ZTimeField.swift
//  capsulefm
//
//  Created by Tor Langballe on /25/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZTimeField : ZShapeView {
    var time: ZTime
    var picker: ZDatePicker? = nil
    var edited = false
    var showTime = true
    var showDate = true
    var showYear = true
    var showSeconds = true
    init(time:ZTime, use24Hour:Bool = true, fiveMins:Bool = false) {
        self.time = time
        super.init(type:.roundRect, minSize: ZSize(40, 38))
        
        setTextFromTime()
        HandlePressedInPosFunc = { [weak self] (pos) in
            let v1 = ZVStackView(space:2)
            self!.picker = ZDatePicker(time:time, useTime:self!.showTime, useDate:self!.showDate, minuteInterval:5)
            self!.picker!.TextColor = self!.text.color
            self!.picker!.ValueChangedTarget = self            
            let confirm = ZConfirmStack() { (result) in
                if result {
                    self!.edited = true
                    self!.time = ZTime(date:self!.picker!.date)
                    self!.setTextFromTime()
                    self!.Expose()
                }
                ZPopTopView()
            }
            v1.Add(confirm, align:.Center | .HorExpand | .NonProp)
            v1.Add(self!.picker!, align:.Center)
            ZPresentView(v1)
        }
    }
    
    fileprivate func setTextFromTime() {
        var sdate = ""
        var stime = ""
        
        if showTime {
            stime = "HH:mm"
        }
        if showDate {
            sdate = "MMM-dd"
        }
        if showYear {
            sdate = "YYYY-" + sdate
        }
        if showSeconds {
            stime += "::ss"
        }
        let format = ZStr.ConcatNonEmpty(sep:" ", items:[sdate, stime])
        text.text = time.GetString(format:format)
    }
    
    func HandlePicked(_ hour: Int, min: Int, am: Bool) {
        let h24 = ZTime.Get24Hour(hour, am:am)
        time = ZTime(year:-1, hour:h24, minute:min)
        valueTarget?.HandleValueChanged(self)
    }
    
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    required init(name: String) { fatalError("init(name:) has not been implemented") }
}

