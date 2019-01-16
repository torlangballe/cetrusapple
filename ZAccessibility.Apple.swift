//
//  ZAccessibility.swift
//  Cetrus
//
//  Created by Tor Langballe on /28/11/15.
//

import UIKit

class ZAccessibilty {
    static var IsOn: Bool {
      get { return UIAccessibility.isVoiceOverRunning }
    }

    static func ConvertRect(_ rect:ZRect, view:ZView) -> ZRect {
      return ZRect(UIAccessibility.convertToScreenCoordinates(rect.GetCGRect(), in: view.View()))
    }

    static func SayNotification(_ message:String) {
      UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: message)
    }

    static func SayScrollNotification(_ message:String) {
      UIAccessibility.post(notification: UIAccessibility.Notification.pageScrolled, argument: message)
    }
    
    static func SendScreenUpdateNotification(_ message:String = "") {
      UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: message)
    }
}
