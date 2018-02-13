//
//  File.swift
//  Zed
//
//  Created by Tor Langballe on /12/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZScreen {
    enum Layout:Int { case portrait, portraitUpsideDown, landscapeLeft, landscapeRight }

    static var isLocked: Bool = false
    static var MainUsableRect = ZRect(UIScreen.main.bounds)
    static var Scale = Float(UIScreen.main.scale)
    static var KeyboardRect: ZRect? = nil
    
    static var Main: ZRect {
        get {
            return ZRect(UIScreen.main.bounds)
        }
    }

    static var StatusBarHeight : Double {
        get {
            return Double(UIApplication.shared.statusBarFrame.size.height)
        }
    }
    
    static var IsTall: Bool {
        get {
            return Main.size.h > 568
        }
    }

    static var IsWide: Bool {
        get {
            return Main.size.w > 320
        }
    }
    
    static var IsPortrait: Bool {
        get {
            return Main.size.h > Main.size.w
        }
    }

    static func ShowNetworkActivityIndicator(_ show:Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = show
    }
    
    static var HasSleepButtonOnSide : Bool {
        get {
            let (_, version, name, _) = ZDevice.DeviceType
            if name == "iPhone" && version >= 70 {
                return true
            }
            return false
        }
    }
    
    static var StatusBarVisible : Bool {
        get {
            return !UIApplication.shared.isStatusBarHidden
        }
        set {
            UIApplication.shared.isStatusBarHidden = !newValue
        }
    }
    
    static func SetStatusBarForLightContent(_ light:Bool = true) {
        UIApplication.shared.statusBarStyle = light ? .lightContent : .default
    }
    
    static func EnableIdle(_ on:Bool = true) {
        UIApplication.shared.isIdleTimerDisabled = !on
    }
    
    static func Orientation() -> Layout {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    static func HasNotch() -> Bool {
        if #available(iOS 11.0, *) {
            if ((UIApplication.shared.keyWindow?.safeAreaInsets.top)! > CGFloat(0.0)) {
                return true
            }
        }
        return false
    }

    static func HasSwipeUpAtBottom() -> Bool {
        if #available(iOS 11.0, *) {
            if (UIApplication.shared.keyWindow?.safeAreaInsets.bottom)! != 0 {
                return true
            }
        }
        return false
    }
}
