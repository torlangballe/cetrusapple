//
//  ZNotification.swift
//  Zed
//
//  Created by Tor Langballe on /25/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit
import UserNotifications

// https://useyourloaf.com/blog/local-notifications-with-ios-10/

struct ZNotificationAction
{
    var sid = ""
    var title = ""
    var background = false // background is to iOS on watch!
    var destructive = false // red button?
    var authRequired = false
    var inMini = true // if false, it doesn't show in small notif
}

typealias ZNotification = UNNotificationRequest

struct ZNotificationInfo {
    var sendInSecs:Float = 0
    var repeats:Bool = false
    var triggerTime:ZTime = ZTimeNull
    var soundName = ""
    var title = ""
    var body = ""
    var userInfo: [AnyHashable : Any] = [:]
    var categoryId = ""
}

extension ZNotification {
    convenience init(suid:String, info:ZNotificationInfo) {
        var secs = Double(info.sendInSecs)
        if !info.triggerTime.IsNull {
            secs = info.triggerTime.Until()
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:secs, repeats:info.repeats)
        let c = UNMutableNotificationContent()
        c.title = info.title
        c.body = info.body
        c.userInfo = info.userInfo
        if !info.soundName.isEmpty {
            c.sound = UNNotificationSound(named:info.soundName)
        }
        if !info.categoryId.isEmpty {
            c.categoryIdentifier = info.categoryId
        }
        self.init(identifier:suid, content:c, trigger:trigger)
    }
    
    func SendLocal(done:@escaping (_ err:ZError?)->Void) {
        let center = UNUserNotificationCenter.current()
        center.add(self) { (error) in
            ZDebug.Print("ZNotifcation.SendLocal done:", error)
            done(error)
        }
        ZDebug.Print("ZNotification.SendLocal:", self.trigger!)
    }
    
    class func CancelAllLocal() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    class func SetBadgeNumber(_ n:Int) {
        UIApplication.shared.applicationIconBadgeNumber = n
    }
/*
    static func IsAuthenticatedForLocal() -> Bool {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                return false
            }
        }
        return true
    }
  */
    
    static func RegisterForNotifications(_ actions:[ZNotificationAction] = [], categoryId:String = "") {
        let center = UNUserNotificationCenter.current()

        let options: UNAuthorizationOptions = [.alert, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                ZDebug.Print("Notification authentication not granted:", error)
            }
        }

        if categoryId.isEmpty {
            return
        }
        for c in registeredCategories {
            if c.identifier == categoryId {
                return
            }
        }
        var unActions = [UNNotificationAction]()
        for action in actions {
            var opts = UNNotificationActionOptions()
            if action.authRequired {
                opts.update(with:.authenticationRequired)
            }
            if action.destructive {
                opts.update(with:.destructive)
            }
            if !action.background {
                opts.update(with:.foreground)
            }
            let a = UNNotificationAction(identifier:action.sid, title:action.title, options:opts)
            unActions.append(a)
        }
        let category = UNNotificationCategory(identifier:categoryId,
                                      actions:unActions,
                                      intentIdentifiers:[], options:UNNotificationCategoryOptions())
        registeredCategories.update(with:category)
        center.setNotificationCategories(registeredCategories)
    }
    
    static func RegisterForPushNotifications() {
        let center  = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
            if error == nil{
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    static func IsRegisteredForRemoteNotifications() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }
}


var registeredCategories = Set<UNNotificationCategory>()

