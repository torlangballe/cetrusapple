//
//  FBAppController.swift
//
//  Created by Tor Langballe on /13/12/17.
//

import Foundation
//import Darwin
//import UserNotifications

//@UIApplicationMain
class ZFBAppController : ZAppController {
    override func applicationDidFinishLaunching(_ application: UIApplication) {
        super.applicationDidFinishLaunching(application)
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions:nil)
    }
    
    override func applicationDidBecomeActive(_ application:UIApplication) {
        super.applicationDidBecomeActive(application)
        FBSDKAppEvents.activateApp()
    }
    
    override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, open:url, sourceApplication:sourceApplication, annotation:annotation)
        if handled {
            return true
        }
        return super.application(application, open:url, sourceApplication:sourceApplication, annotation:annotation)
    }
}


