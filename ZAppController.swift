//
//  ZAppController.swift
//  Zed
//
//  Created by Tor Langballe on /27/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import AVFoundation
import Darwin
import MediaPlayer
import UserNotifications

// https://www.raywenderlich.com/123862/push-notifications-tutorial

// @UIApplicationMain // this adds a main function that sets UIApplicationDelegate and runs event loop I think
class ZAppController : UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow? = nil
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Info = ", notification.request.content.userInfo)
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        mainZApp!.HandleAppNotification(response.notification.request, action:response.actionIdentifier)
        print("User Info = ",response.notification.request.content.userInfo)
        completionHandler()
    }
    /*
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        mainZApp!.HandleAppNotification(notification, action:identifier ?? "")
        completionHandler()
    }
    */
    
    @objc func handleInterruption(_ notification:Notification) {
        if let ntype = (notification as NSNotification).userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt {
            print(ntype)
            if ntype == AVAudioSessionInterruptionType.began.rawValue {
                mainZApp!.HandleAudioInterrupted()
            } else {
                if let number = (notification as NSNotification).userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    if number == AVAudioSessionInterruptionOptions.shouldResume.rawValue {
                        mainZApp!.HandleAudioResume()
                        //                        ZAudioSession.SetAppIsPlayingSound(true, mixWithOthers:true) // dangerous...
                    }
                }
            }
        }
    }
        
    @objc func handleAudioRouteChanged(_ notification:Notification) {
        if let number = (notification as NSNotification).userInfo?[AVAudioSessionRouteChangeReasonKey] as? Int {
            mainZApp!.HandleAudioRouteChanged(number)
        }
    }
    
    @objc func voiceOverStatusChanged(_ notification:Notification) {
        mainZApp!.HandleVoiceOverStatusChanged()
    }
    
    /*
    - (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
    {
    NSURL *url;
    
    url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    zapp->HandleOpenURL(MacNSURLToZStr(url));
    }
    */
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        ZScreen.KeyboardRect = ZRect(frame)
    }

    private func application(_ application: UIApplication, didRegister notificationSettings: UNNotificationSetting) {
//        if notificationSettings == .notSupported
//            application.registerForRemoteNotifications()
//        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        
        for i in 0 ..< deviceToken.count {
            tokenString += ZStr.Format( "%02.2hhx", [tokenChars[i]])
        }
        mainZApp?.HandleGotPushToken(tokenString)
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ZDebug.Print("Failed to register:", error)
    }

    //    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    @objc func changedThumbSliderOnLockScreen(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        mainZApp?.HandleRemoteAudioSeekTo(posSecs:event.positionTime)
        return .success
    }

    @objc func togglePlayPause(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        mainZApp?.HandleAudioRemote(.togglePlayPause)
        return .success
    }

    @objc func nextTrack(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        mainZApp?.HandleAudioRemote(.nextTrack)
        return .success
    }
    
    @objc func previousTrack(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        mainZApp?.HandleAudioRemote(.previousTrack)
        return .success
    }

    @objc func lowDiskSpaceForOnDemandResource(notification:NSNotification) {
        ZDebug.Print("lowDiskSpaceForOnDemandNSBundle")
    }
    

    func applicationDidFinishLaunching(_ application: UIApplication) {
        let launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil
//!        mainAnalytics.InitCrashReporter()

        /*
        extern WCSession *wcSession;
        if(ZWatch::responder && [WCSession isSupported]) {
        wcSession = [WCSession defaultSession];
        wcSession.delegate = self;
        [wcSession activateSession];
        ZDebugStr("WCSession activated");
        }
        */
                
        /*
        var  gotRecept = false
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            ZDebug.Print("receiptURL:", receiptURL)
            if let receipt = NSData(contentsOf: receiptURL) {
                ZDebug.Print("receipt:", receipt)
                gotRecept = true
            }
        }
        if !gotRecept {
            ZDebug.Print("no receipt!")
            exit(173)
        }
*/

        UNUserNotificationCenter.current().delegate = self

        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector:#selector(ZAppController.handleInterruption(_:)), name:NSNotification.Name.AVAudioSessionInterruption, object:AVAudioSession.sharedInstance())
        
        nc.addObserver(self, selector:#selector(ZAppController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object:nil)
        

        // later in your class:
        
        func keyboardWillShow(_ notification: Notification) {
            if let frame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                ZScreen.KeyboardRect = ZRect(frame)
            }
        }

        // http://stackoverflow.com/questions/31429800/how-to-check-if-the-ios-device-is-locked-unlocked-using-swift
        nc.addObserver(self, selector:#selector(ZAppController.handleAudioRouteChanged(_:)), name:NSNotification.Name.AVAudioSessionRouteChange, object:nil)
        if #available(iOS 11.0, *) {
            nc.addObserver(self, selector:#selector(ZAppController.voiceOverStatusChanged(_:)), name:NSNotification.Name.UIAccessibilityVoiceOverStatusDidChange, object:nil)
        } else {
            // Fallback on earlier versions
        }
        
//!        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions:launchOptions)

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = ZViewController()
        //        self.window!.backgroundColor = UIColor.grayColor()
        self.window!.makeKeyAndVisible()
        ZApp.appFile = ZFileUrl(filePath:CommandLine.arguments[0])
        let args = Array(CommandLine.arguments[1..<CommandLine.arguments.count])

        ZApp.Main(args) // don't use mainZApp before this!!!

//        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? ZNotification {
//            mainZApp!.HandleAppNotification(notification, action:"")
//            application.statusBarStyle = UIStatusBarStyle.lightContent
//        }
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: AnyObject] {
            let aps = notification["aps"] as! [String: AnyObject]
            PerformAfterDelay(0.5) { () in
                mainZApp?.HandlePushNotificationWithDictionary(aps, fromStartup:true, whileActive:false)
            }
        }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget(self, action:#selector(ZAppController.changedThumbSliderOnLockScreen))

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget(self, action:#selector(ZAppController.togglePlayPause))

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action:#selector(ZAppController.nextTrack))

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget(self, action:#selector(ZAppController.previousTrack))


        //        GeneralNSObject.registerAppforDetectLockState(mainZApp!)

        //!        return true;

        nc.addObserver(self, selector:#selector(ZAppController.lowDiskSpaceForOnDemandResource), name:NSNotification.Name.NSBundleResourceRequestLowDiskSpace, object:nil)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // http://stackoverflow.com/questions/5056689/didreceiveremotenotification-when-in-background
        let aps = userInfo["aps"] as! [String: AnyObject]
        mainZApp?.HandlePushNotificationWithDictionary(aps, fromStartup:false, whileActive:application.applicationState == .active)
    }
    
    func applicationDidEnterBackground(_ application:UIApplication) {
        mainZApp?.backgroundTime = ZTimeNow
        mainZApp?.activationTime = ZTimeNull
        mainZApp?.HandleBackgrounded(true)
    }
    
    func applicationWillEnterForeground(_ application:UIApplication) {
        mainZApp?.activationTime = ZTimeNow
        mainZApp?.backgroundTime = ZTimeNull
        mainZApp?.HandleBackgrounded(false)
    }
    
    func applicationWillResignActive(_ application:UIApplication) {
        mainZApp?.HandleActivated(false)
        mainZApp?.activationTime = ZTimeNull
        ZRecusivelyHandleActivation(activated:false)
    }
    
    func applicationWillTerminate(_ application:UIApplication) {
        ZDebug.Print("applicationWillTerminate!");
        mainZApp?.HandleAppWillTerminate()
    }
    
    func applicationDidBecomeActive(_ application:UIApplication) {
//!        FBSDKAppEvents.activateApp()
        mainZApp?.activationTime = ZTimeNow
        mainZApp?.HandleActivated(true)
        ZRecusivelyHandleActivation(activated:true)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.scheme == "file" {
            let file = ZFileUrl(nsUrl:url)
            mainZApp?.HandleOpenedFiles([file], modifiers:0)
            return true
        }
//!        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, open:url, sourceApplication:sourceApplication, annotation:annotation)
//        if handled {
//            return true
//        }
        return mainZApp!.HandleOpenUrl(ZUrl(nsUrl:url))
    }
/*
    func application(app:UIApplication, openURL url:NSURL, options:[String : AnyObject]) -> Bool {
        //            #if !ZIPHONEOS
        //                mods = ZKey::GetModifiers();
        //            #endif
    }
  */
  
    func willChangeStatusBarFrame(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let value = userInfo[UIApplicationStatusBarFrameUserInfoKey] as? NSValue {
                let statusBarFrame = value.cgRectValue
                let transitionView = UIApplication.shared.delegate!.window!!.subviews.last! as UIView
                var frame = transitionView.frame
                frame.origin.y = statusBarFrame.height-20
                frame.size.height = UIScreen.main.bounds.height-frame.origin.y
                ZScreen.MainUsableRect = ZRect(frame)
            }
        }
    }

    func application(_ application: UIApplication, didChangeStatusBarFrame oldStatusBarFrame: CGRect) {
        // tell all windows
    }
    //    func UIApplicationMain() {    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        /*
         Store the completion handler.
         */
//        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }

    static func RunApp(delegateClass:Swift.AnyClass) {
        UIApplicationMain(CommandLine.argc, convertArgs(CommandLine.unsafeArgv), nil, NSStringFromClass(delegateClass.self))
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        mainZApp?.HandleMemoryNearFull()
    }
}

private func convertArgs(_ args:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> UnsafeMutablePointer<UnsafeMutablePointer<Int8>>! {
    return UnsafeMutableRawPointer(args).bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc))
}


