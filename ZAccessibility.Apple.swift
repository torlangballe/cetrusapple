//
//  ZAccessibility.swift
//  Cetrus
//
//  Created by Tor Langballe on /28/11/15.
//

import UIKit

class ZAccessibilty {
    static var IsOn: Bool {
        get { return UIAccessibilityIsVoiceOverRunning() }
    }

    static func ConvertRect(_ rect:ZRect, view:ZView) -> ZRect {
        return ZRect(UIAccessibilityConvertFrameToScreenCoordinates(rect.GetCGRect(), view.View()))
    }

    static func SayNotification(_ message:String) {
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message)
    }

    static func SayScrollNotification(_ message:String) {
        UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, message)
    }
    
    static func SendScreenUpdateNotification(_ message:String = "") {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, message)
    }
}
