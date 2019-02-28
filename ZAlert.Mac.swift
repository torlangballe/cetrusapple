//
//  ZAlert.Mac.swift
//
//  Created by Tor Langballe on 21/02/2019.
//

import AppKit

class ZAlert {
    enum Result: Int { case ok = 1, cancel = 2, destructive = 3, other = 4 }
    static let DefOk = "🆗"
    static let DefCancel = "❌"
    
    static func Say(_ text:String, ok:String = DefOk, cancel:String = "", other:String = "", destructive:String = "", subText:String = "", pressed:((_ result:Result)->Void)? = nil)  {
        var vok = ok
        var vcancel = cancel
        if vok == DefOk  {
            vok = ZWords.GetOk()
        }
        if vcancel == DefCancel {
            vcancel = ZWords.GetCancel()
        }
        let alert = NSAlert()
        alert.addButton(withTitle: vok)
        if !vcancel.isEmpty {
            alert.addButton(withTitle: vcancel)
        }
        if !other.isEmpty {
            alert.addButton(withTitle: other)
        }
        if !destructive.isEmpty {
            alert.addButton(withTitle: destructive)
        }
        alert.messageText = text
//        alert.alertStyle = NSAlertStyle.warning
        alert.informativeText = subText
        alert.runModal()
    }
    
    // static func GetText(_ title:String, content:String = "", placeholder:String = "", ok:String = "", cancel:String = "", other:String? = nil, subText:String = "", keyboardInfo:ZKeyboardInfo? = nil, done:@escaping (_ text:String, _ result:Result)->Void)  { }
    
    static func ShowError(_ text:String, error:ZError) {
        ZAlert.Say(text, subText:error.GetMessage())
        ZDebug.Print("Show Error:\n", text)
    }
}

