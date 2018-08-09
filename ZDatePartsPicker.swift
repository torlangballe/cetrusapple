//
//  ZDatePartsPicker.swift
//  capsulefm
//
//  Created by Tor Langballe on /12/7/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

protocol ZDatePartsPickerDelegate : class {
    func HandlePicked(_ year:Int?, month:Int?, day:Int?)
}

class ZDatePartsPicker : ZLabelPickerView {
    enum Part: Int { case day = 0, month, year }
    var year:Int? = nil
    var month: Int? = nil
    var day:Int? = nil
    var optionalYear = false
    var optionalMonth = false
    var optionalDay = false
    var useYear:Bool
    var startYear = 1900
    var endYear:Int
    var monthChars:Int
    var isSetup = false
    
    weak var datePickDelegate: ZDatePartsPickerDelegate? = nil
    
    init(useYear:Bool = false, monthChars:Int) {
        endYear = ZTimeNow.GetGregorianDateParts().year
        self.useYear = useYear
        self.monthChars = monthChars
        super.init(frame: ZRect(0, 0, 200, 216))
        objectName = "datepartspicker"
        
        columns.append(Column()) // month
        columns.append(Column()) // day
        if useYear {
            columns.append(Column()) // year
        }
    }
    
    func Setup() {
        isSetup = true
        if useYear {
            if optionalYear {
                columns[Part.year.rawValue].titles.append(" ")
            }
            for i in (startYear ... endYear).reversed() {
                let y = "\(i)" + ZLocale.GetDateInsertYearSymbol()
                columns[Part.year.rawValue].titles.append(y)
            }
        }
        if optionalMonth {
            columns[Part.month.rawValue].titles.append(" ")
        }
        for i in 1 ... 12 {
            let m = ZLocale.GetMonthFromNumber(i, chars:monthChars) + ZLocale.GetDateInsertMonthSymbol()
            columns[Part.month.rawValue].titles.append(m)
        }
        if optionalDay {
            columns[Part.day.rawValue].titles.append(" ")
        }
        for i in 1 ... 31 {
            let m = "\(i)" + ZLocale.GetDateInsertDaySymbol()
            columns[Part.day.rawValue].titles.append(m)
        }

        columns[Part.year.rawValue].wrap = false
        columns[Part.month.rawValue].wrap = false
        columns[Part.day.rawValue].wrap = false
        
        columns[Part.year.rawValue].name = ZLocale.GetYear()
        columns[Part.month.rawValue].name = ZLocale.GetMonth()
        columns[Part.day.rawValue].name = ZLocale.GetDayOfMonth()
        
        Reload()
        Refresh()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let r = row % columns[component].titles.count
        let str = columns[component].titles[r]
        super.pickerView(pickerView, didSelectRow:row, inComponent:component)
        switch component {
            case Part.year.rawValue:
                if str == " " {
                    year = nil
                } else {
                    year = Int(str)
                }
            
        case Part.month.rawValue:
                if str == " " {
                    month = nil
                } else {
                    var i = r + 1
                    if optionalMonth {
                        i -= 1
                    }
                    month = i
                }
            
        case Part.day.rawValue:
            if str == " " {
                day = nil
            } else {
                day = Int(str)
            }

        default:
            break
        }
        datePickDelegate?.HandlePicked(year, month:month, day:day)
    }
    
    func SetValues(_ y:Int? = nil, m:Int?, d:Int?, animate:Bool = true, tell:Bool = false) {
        assert(isSetup)
        var str = ""
        if useYear {
            year = y
            if y == nil {
                str = " "
            } else {
                str = "\(y!)"
            }
            SetWithTitle(str, column:Part.year.rawValue, animated:animate)
        }

        month = m
        if m == nil {
            str = " "
        } else {
            str = ZLocale.GetMonthFromNumber(m!, chars:monthChars)
        }
        SetWithTitle(str, column:Part.month.rawValue, animated:animate)

        day = d
        if d == nil {
            str = " "
        } else {
            str = "\(d!)"
        }
        SetWithTitle(str, column:Part.day.rawValue, animated:animate)

        if tell {
            datePickDelegate?.HandlePicked(year, month:month, day:day)
        }
    }
}
