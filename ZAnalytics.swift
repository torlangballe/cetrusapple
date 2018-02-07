//
//  ZAnalytics.swift
//  capsulefm
//
//  Created by Tor Langballe on /31/8/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation
//import Fabric
import Crashlytics

//import HockeySDK

class ZAnalytics {
    var trackers = [GAITracker]()
    
    init() {
        let gs = GAI.sharedInstance()
        // gs?.trackUncaughtExceptions = true
        gs?.dispatchInterval = 20
        gs?.logger!.logLevel = .info // .verbose // .none
    }
    
    func AddTracker(_ name:String, id:String) {
        let tracker = GAI.sharedInstance().tracker(withName: name, trackingId:id)
        addTracker(tracker!)
    }
    
    fileprivate func addTracker(_ tracker:GAITracker) {
        trackers.append(tracker)
        var (version, _, build) = ZApp.Version
        if build > 0 {
            version += " b\(build)"
        }
        SetValue(kGAIAppVersion, value:version)
    }

    func SetValue(_ key:String, value:String?) {
        let builder = GAIDictionaryBuilder()
        
        builder.set(key, forKey: value)
            
        if let dict = (builder.build() as NSDictionary) as? [AnyHashable: Any] {
            for t in trackers {
                t.send(dict)
            }
        }
    }
    
    func SetViewName(_ name:String) {
        for t in trackers {
            t.set(kGAIScreenName, value: name)
            t.send(GAIDictionaryBuilder.createScreenView().build() as NSDictionary as? [AnyHashable: Any])
        }
        //        SetValue(kGAIScreenName, value:name)
    }

    func SetUserId(_ id:String, email:String, name:String="") {
        SetValue(kGAIUserId, value:id)
        
        if !email.isEmpty {
            Crashlytics.sharedInstance().setUserEmail(email)
        }
        if !id.isEmpty {
            Crashlytics.sharedInstance().setUserIdentifier(id)
        }
        if !name.isEmpty {
            Crashlytics.sharedInstance().setUserName(name)
        }
        //        BITHockeyManager.shared().userID = id
        //        BITHockeyManager.shared().userEmail = email
    }
    
    func SendEvent(_ category:String, action:String, label:String = "", value:Double? = nil) {
        let builder = GAIDictionaryBuilder.createEvent(withCategory: category, action:action, label:label, value:value as NSNumber!)
        if let dict = (builder!.build() as NSDictionary) as? [AnyHashable: Any] {
            for t in trackers {
                t.send(dict)
            }
        }
    }
 
    func InitCrashReporter() {
        Crashlytics().debugMode = true
        /*
        let shared = BITHockeyManager.shared()
        shared.configure(withIdentifier:"b8c90f7a36c0459899bda324de819f9e")
        shared.crashManager.crashManagerStatus = .autoSend
        //        shared.authenticator.authenticateInstallation()
        shared.isUpdateManagerDisabled = true
        shared.logLevel = .debug
        shared.start()
 */
    }
    
    static func Crash() {
        ZDebug.Print("Crash!")
        Crashlytics.sharedInstance().crash()
    }
}

let mainAnalytics = ZAnalytics()

