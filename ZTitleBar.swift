//
//  ZTitleBar.swift
//
//  Created by Tor Langballe on /16/11/15.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

class ZTitleBar : ZStackView {
    enum CloseButtons: String { case left = "arrow.left", down = "arrow.down", cross = "cross", none = "" }
    var closeButton: ZImageView
    let notchInc = 16
    let title: ZLabel
    var sizeCalculated = false
    weak var closeHandler:ZViewHandler? = nil
    
    static var Color = ZColor(r:0.2, g:0.3, b:1)
    
    init(text:String = "", closeType:CloseButtons = CloseButtons.cross, closeAlignX:ZAlignment = ZAlignment.Left) {
        closeButton = ZImageView(namedImage:closeType.rawValue + ".png")
        title = ZLabel(text:text, maxWidth:ZScreen.Main.size.w, font:ZFont.Nice(25.0), align:ZAlignment.Left)
        title.Color = ZColor.White()
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.5

        super.init(name:"titlebar")
        
        space = 0.0
        margin = ZRect(0.0, 0.0, 0.0, -4.0)
        accessibilityLabel = text
        minSize = ZSize(100, 60)
//        if ZScreen.HasNotch() {
//            minSize.h += 88
//        }
        closeButton.AddTarget(self, forEventType:ZControlEventType.pressed)
        closeButton.accessibilityLabel = ZWords.GetClose()
        AddTarget(self, forEventType:ZControlEventType.pressed)
        Add(closeButton, align:closeAlignX | ZAlignment.Bottom)
        Add(title, align:ZAlignment.HorCenter | ZAlignment.Bottom, marg:ZSize(0, 5))
        SetBackgroundColor(ZTitleBar.Color)
        minSize.h = 44.0
        if ZIsIOS() {
            minSize.h += ZScreen.StatusBarHeight
        }
    }

    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
    
    override func HandlePressed(_ sender: ZView, pos:ZPos) {
        if sender.View() == closeButton {
            if closeHandler != nil {
                closeHandler!.HandleClose(sender:self)
            } else {
                ZPopTopView() //overrideDuration:0) //, overrideTransition:.fade)
            }
        } else {
            ZTextDismissKeyboard()
        }
    }

    override func HandleBeforeLayout() {
        if !sizeCalculated {
            sizeCalculated = true
            RangeChildren() { [weak self] (view) in
                if view.View() != title {
                    self?.title.maxWidth -= (view.Rect.size.w + space)
                }
                return true
            }
        }
    }
    
    func ShowActivity(_ show:Bool = true) {
        if show && FindCellWithName("activity") == nil {            
            let activity = ZActivityIndicator(big:false)
            Add(activity, align:ZAlignment.VertCenter | ZAlignment.Right)
            activity.Start()
        } else {
            RemoveNamedChild("activity")
        }
        ArrangeChildren()
    }
}
