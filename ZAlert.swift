//
//  ZAlert.swift
//  Cetrus
//
//  Created by Tor Langballe on /7/11/15.
//

import UIKit

class ZAlert {
    enum Result: Int { case ok = 1, cancel = 2, destructive = 3, other = 4 }
    static func Say(_ text:String, ok:String = "🆗", cancel:String = "", other:String = "", destructive:String = "", subText:String = "", pressed:((_ result:Result)->Void)? = nil)  {
        let view = UIAlertController(title:text, message:subText, preferredStyle:UIAlertControllerStyle.alert)

        var vok = ok
        var vcancel = cancel
        if vok ==  "🆗" {
            vok = ZLocale.GetOk()
        }
        if vcancel == "❌" {
            vcancel = ZLocale.GetCancel()
        }
        view.addAction(UIAlertAction(title:vok, style:.default) { (UIAlertAction) in
            if pressed != nil {
                pressed!(Result.ok)
            }
        })
        if vcancel != "" {
            view.addAction(UIAlertAction(title:vcancel, style:.cancel) { (UIAlertAction) in
                if pressed != nil {
                    pressed!(Result.cancel)
                }
            })
        }
        if other != "" {
            view.addAction(UIAlertAction(title:other, style:.default) { (UIAlertAction) in
                if pressed != nil {
                    pressed!(Result.other)
                }
            })
        }
        if destructive != "" {
            view.addAction(UIAlertAction(title:destructive, style:.destructive) { (UIAlertAction) in
                if pressed != nil {
                    pressed!(Result.destructive)
                }
            })
        }
        ZGetTopViewController()!.present(view, animated:true, completion:nil)
    }

    static func GetText(_ title:String, content:String = "", placeholder:String = "", ok:String = "", cancel:String = "", other:String? = nil, subText:String = "", keyboardInfo:ZKeyboardInfo? = nil, done:@escaping (_ text:String, _ result:Result)->Void)  {
        var vok = ok
        var vcancel = cancel
        
        let view = UIAlertController(title:title, message:subText, preferredStyle:UIAlertControllerStyle.alert)
        
        if vok.isEmpty {
            vok = ZLocale.GetOk()
        }
        if vcancel.isEmpty{
            vcancel = ZLocale.GetCancel()
        }
        
        let okAction = UIAlertAction(title:vok, style:.default) { (UIAlertAction) in
            let str = view.textFields?.first!.text ?? ""
            done(str, .ok)
        }
        view.addAction(okAction)
        view.addAction(UIAlertAction(title:vcancel, style:.cancel) { (UIAlertAction) in
            done("", .cancel)
        })
        if other != nil {
            let otherAction = UIAlertAction(title:other!, style:.default) { (UIAlertAction) in
                let str = view.textFields?.first!.text ?? ""
                done(str, .other)
            }
            view.addAction(otherAction)
        }
        view.addTextField { (textField) in
            textField.placeholder = placeholder
            if keyboardInfo != nil {
                if keyboardInfo!.keyboardType != nil {
                    textField.keyboardType = keyboardInfo!.keyboardType!
                }
                if keyboardInfo!.autoCapType != nil {
                    textField.autocapitalizationType = keyboardInfo!.autoCapType!
                }
                if keyboardInfo!.returnType != nil {
                    textField.returnKeyType = keyboardInfo!.returnType!
                }
            }
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                okAction.isEnabled = textField.text != ""
            }
        }
        ZGetTopViewController()!.present(view, animated:true, completion:nil)
    }
/*
    static func ShowShareView(_ objects:[AnyObject], openInSafari:Bool) {
        var activities = [UIActivity]()
        if openInSafari {
            activities.append(TUSafariActivity())
        }
        var newObjects = [AnyObject]()
        for c in objects {
            if let u = c as? ZUrl {
                newObjects.append(u.url! as AnyObject)
            } else {
                newObjects.append(c)
            }
        }
        //        activities.append(UIActivityTypeAddToReadingList) // newObjects
        let activityVC = UIActivityViewController(activityItems:newObjects, applicationActivities:activities)
        
        activityVC.excludedActivityTypes = [UIActivityType.airDrop]
        ZGetTopViewController()!.present(activityVC, animated:true, completion:nil)
    }
    */
    
    static func ShowError(_ text:String, error:Error) {
        ZAlert.Say(text, subText:error.GetMessage())
        ZDebug.Print("Show Error:\n", text)
    }
}

