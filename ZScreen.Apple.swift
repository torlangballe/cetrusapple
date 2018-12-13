//
//  File.swift
//  Zed
//
//  Created by Tor Langballe on /12/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

enum ZScreenLayout:Int { case portrait, portraitUpsideDown, landscapeLeft, landscapeRight }

class ZScreen {
    static var isLocked: Bool = false
    static var MainUsableRect = ZRect(UIScreen.main.bounds)
    static var Scale = Double(UIScreen.main.scale)
    static var SoftScale = 1.0
    static var KeyboardRect: ZRect? = nil
    
    static var Main: ZRect {
        get {
            return ZRect(UIScreen.main.bounds)
        }
    }

    static var StatusBarHeight : Double {
        get {
            #if os(iOS)
            return Double(UIApplication.shared.statusBarFrame.size.height)
            #else
            return 0
            #endif
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
        #if os(iOS)
        UIApplication.shared.isNetworkActivityIndicatorVisible = show
        #endif
    }
    
    static var HasSleepButtonOnSide : Bool {
        get {
            let (_, version, name, _) = ZDevice.DeviceCodeNumbered
            if name == "iPhone" && version >= 70 {
                return true
            }
            return false
        }
    }
    
    static var StatusBarVisible : Bool {
        get {
            #if os(iOS)
            return !UIApplication.shared.isStatusBarHidden
            #else
            return false
            #endif
        }
        set {
            #if os(iOS)
            UIApplication.shared.isStatusBarHidden = !newValue
            #endif
        }
    }
    
    static func SetStatusBarForLightContent(_ light:Bool = true) {
        #if os(iOS)
        UIApplication.shared.statusBarStyle = light ? .lightContent : .default
        #endif
    }
    
    static func EnableIdle(_ on:Bool = true) {
        UIApplication.shared.isIdleTimerDisabled = !on
    }
    
    static func Orientation() -> ZScreenLayout {
        #if os(iOS)
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
        #else
        return .landscapeLeft
        #endif
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
