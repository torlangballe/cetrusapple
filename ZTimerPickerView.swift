//
//  ZTimerPickerView.swift
//  Zed
//
//  Created by Tor Langballe on /12/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit


func getFormatedHours(_ h:Int, use24:Bool) -> String {
    if(use24) {
        return ZStr.Format("%02d", h);
    } else {
        return ZStr.Format("%d", h);
    }
}

protocol ZTimePickerDelegate : class {
    func HandlePicked(_ hour:Int, min:Int, am:Bool)
}

class ZTimePickerView : ZLabelPickerView {
    enum Part: Int { case hour = 0, min, amPm } // Dots
    var uses24hour = false
    var sam = "am"
    var spm = "pm"
    var minute = 0
    var hour = 0
    var isAm = false
    var fiveMins = false
    weak var timePickDelegate: ZTimePickerDelegate? = nil
    
    init(use24Hour:Bool = true, fiveMins:Bool = false) {
        self.fiveMins = fiveMins
        self.uses24hour = use24Hour
        let inc = fiveMins ? 5 : 1
        
        super.init(frame: ZRect(0, 0, 200, 216))
        objectName = "ZTimePickerView"

        columns.append(Column()) // hour
        columns.append(Column()) // mins
        if uses24hour {
            for i in 0 ..< 24 {
                columns[Part.hour.rawValue].titles.append(getFormatedHours(i, use24:uses24hour))
            }
        } else {
            columns.append(Column()) // am/pm
            for i in 1 ... 12 {
                columns[Part.hour.rawValue].titles.append(getFormatedHours(i, use24:uses24hour))
            }
            columns[Part.amPm.rawValue].titles.append(sam)
            columns[Part.amPm.rawValue].titles.append(spm)
            columns[Part.amPm.rawValue].name = ZWords.GetDayPeriod()
        }
        var i = 0
        while i < 60 {
            columns[Part.min.rawValue].titles.append(ZStr.Format("%02d", i))
            i += inc
        }
        //        columns[Part.Dots.rawValue].titles.append(":")
        columns[Part.hour.rawValue].wrap = true
        columns[Part.min.rawValue].wrap = true
        
        columns[Part.hour.rawValue].name = ZWords.GetHour()
        columns[Part.min.rawValue].name = ZWords.GetMinute()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let r = row % columns[component].titles.count
        super.pickerView(pickerView, didSelectRow:row, inComponent:component)
        switch component {
            case Part.hour.rawValue:
                hour = r
                if !uses24hour {
                    hour += 1
                }
            case Part.min.rawValue:
                minute = r
                if fiveMins {
                    minute *= 5
                }
            case Part.amPm.rawValue:
                isAm = (r == 0)
            default:
                break
        }
        if timePickDelegate != nil {
            timePickDelegate?.HandlePicked(hour, min:minute, am:isAm)
        }
    }
    
    func GetHourMinAm(_ h:inout Int, m:inout Int, am:inout Bool) {
        if !uses24hour && hour == 12 {
            h = 0
        } else {
            h = hour
        }
        m = minute
        am = isAm
    }
    func SetTime(_ time:ZTime, animate:Bool = false, tell:Bool = false) {
        var shour = ""
        var am = false
        //        Set(Part.Dots.rawValue, row:0, animated:animate)
        (hour, minute, _, _, _) = time.GetGregorianTimeParts()
        if fiveMins {
            minute = (minute / 5) * 5
        }
        if uses24hour {
            shour = ZStr.Format("%02d", hour)
        } else {
            (am, hour) = ZTime.IsAm(hour:hour)
            shour = ZStr.Format("%d", hour)
        }
        let smin = ZStr.Format("%02d", minute)
        Set(Part.hour.rawValue, row:columns[Part.hour.rawValue].titles.index(of: shour)!, animated:animate)
        Set(Part.min.rawValue, row:columns[Part.min.rawValue].titles.index(of: smin)!, animated:animate)
        if !uses24hour {
            Set(Part.amPm.rawValue, row:am ? 0 : 1)
        }
        if(tell && timePickDelegate != nil) {
            timePickDelegate?.HandlePicked(hour, min:minute, am:isAm)
        }
    }
}

class ZDatePicker : UIDatePicker, ZView {

    var objectName = "datepicker"
    func View() -> UIView {
        return self
    }

    var ValueChangedTarget: ZCustomView? = nil

    var TextColor: ZColor {
        get { return ZColor(color:value(forKey: "textColor") as! UIColor) }
        set { setValue(newValue.color, forKey:"textColor") }
    }
    
    init(time:ZTime, useTime:Bool = true, useDate:Bool = true, minuteInterval:Int = 1) {
        super.init(frame:CGRect(x:0, y:0, width:100, height:100))
        if useTime && useDate {
            datePickerMode = .dateAndTime
        } else if useTime {
            datePickerMode = .time
        } else  {
            datePickerMode = .date
        }
        date = time.date
        self.minuteInterval = minuteInterval
        self.addTarget(self, action:#selector(dateIsChanged(_:)), for:UIControlEvents.valueChanged)
    }
    
    @objc func dateIsChanged(_ sender:UIView?) {
        ValueChangedTarget?.HandleValueChanged(self)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width:216, height:216)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
