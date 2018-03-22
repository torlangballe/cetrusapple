//
//  BottomRow.swift
//  Zed
//
//  Created by Tor Langballe on /16/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZTitleBar : ZStackView {
    enum CloseButtons: String { case left = "arrow.left", down = "arrow.down", cross = "cross", none = "" }
    var closeButton: ZImageView
    let notchInc = 16
    var dots: ZCountDots? = nil
    //    let horStack = ZHStackView(space:16)
    let title: ZLabel
    var sizeCalculated = false
    weak var closeHandler:ZViewHandler? = nil
    
    static var Color = ZColor(r:0.2, g:0.3, b:1)
    
    init(text:String = "", closeType:CloseButtons = .cross, showDots:Bool = false, closeAlignX:ZAlignment = .Left) {
        closeButton = ZImageView(namedImage:closeType.rawValue + ".png")
        title = ZLabel(text:text, maxWidth:ZScreen.Main.size.w, font:ZFont.Nice(25), align:.Left)
        title.Color = ZColor.White()
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.5

        super.init(name:"titlebar")
        
        space = 0
        margin = ZRect(0, 0, 0, -4)
        accessibilityLabel = text
        if showDots {
            dots = ZCountDots()
            dots?.circleWidth = 12
            dots?.circleAlign = .Left
            dots?.space = 1
            Add(dots!, align:.Right | .Bottom, marg:ZSize(2, 8))
        }
        minSize = ZSize(100, 60)
//        if ZScreen.HasNotch() {
//            minSize.h += 88
//        }
        closeButton.AddTarget(self, forEventType:.pressed)
        closeButton.accessibilityLabel = ZLocale.GetClose()
        AddTarget(self, forEventType:.pressed)
        Add(closeButton, align:closeAlignX | .Bottom)
        Add(title, align:.HorCenter | .Bottom, marg:ZSize(0, 5))
        SetBackgroundColor(ZTitleBar.Color)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func SetDotCount(_ count:Int, level:Int, arrange:Bool = false) {
        dots?.Count = count
        dots?.Level = level
        if arrange {
            ArrangeChildrenAnimated()
        }
    }
    
    override func HandlePressed(_ sender: ZView, pos:ZPos) {
        switch sender.View() {
        case closeButton:
            if closeHandler != nil {
                closeHandler!.HandleClose(sender:self)
            } else {
                ZPopTopView() //overrideDuration:0) //, overrideTransition:.fade)
            }
        default:
            ZTextDismissKeyboard()
            break
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
        minSize.h = 44 + ZScreen.StatusBarHeight
    }
    
    func ShowActivity(_ show:Bool = true) {
        if show && FindCellWithName("activity") == nil {            
            let activity = ZActivityIndicator(big:false)
            Add(activity, align:.VertCenter | .Right)
            activity.Start()
        } else {
            RemoveNamedChild("activity")
        }
        ArrangeChildren()
    }
}
