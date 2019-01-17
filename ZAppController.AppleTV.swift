//
//  ZAppController.AppleTV.swift
//
//  Created by Tor Langballe on 11/16/18.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation
import AVFoundation
import Darwin
import MediaPlayer
import UserNotifications

class ZAppController : UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow? = nil
    @objc func handleInterruption(_ notification:Notification) {
        if let ntype = (notification as NSNotification).userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt {
            print(ntype)
            if ntype == AVAudioSession.InterruptionType.began.rawValue {
                mainZApp!.HandleAudioInterrupted()
            } else {
                if let number = (notification as NSNotification).userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    if number == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
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
    
    @objc func keyboardWillShow(_ notification: Notification) {
//        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
//        ZScreen.KeyboardRect = ZRect(frame)
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
        if ZIsTVBox() {
            ZScreen.SoftScale = 2.0
        }
        let launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
        UNUserNotificationCenter.current().delegate = self
        
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector:#selector(ZAppController.handleInterruption(_:)), name:AVAudioSession.interruptionNotification, object:AVAudioSession.sharedInstance())
        
        // later in your class:
        
        func keyboardWillShow(_ notification: Notification) {
//            if let frame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//                ZScreen.KeyboardRect = ZRect(frame)
//            }
        }
        
        // http://stackoverflow.com/questions/31429800/how-to-check-if-the-ios-device-is-locked-unlocked-using-swift
        nc.addObserver(self, selector:#selector(ZAppController.handleAudioRouteChanged(_:)), name:AVAudioSession.routeChangeNotification, object:nil)
        if #available(iOS 11.0, *) {
            nc.addObserver(self, selector:#selector(ZAppController.voiceOverStatusChanged(_:)), name:UIAccessibility.voiceOverStatusDidChangeNotification, object:nil)
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
        
        ZApp.MainFunc?(args) // don't use mainZApp before this!!!
        
//        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: AnyObject] {
//            let aps = notification["aps"] as! [String: AnyObject]
//            ZPerformAfterDelay(0.5) { () in
//                mainZApp?.HandlePushNotificationWithDictionary(aps, fromStartup:true, whileActive:false)
//            }
//        }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
//        commandCenter.changePlaybackPositionCommand.addTarget(self, action:#selector(ZAppController.changedThumbSliderOnLockScreen))
        
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
    
    func applicationDidEnterBackground(_ application:UIApplication) {
        mainZApp?.backgroundTime = ZTime.Now()
        mainZApp?.activationTime = ZTimeNull
        mainZApp?.HandleBackgrounded(true)
    }
    
    func applicationWillEnterForeground(_ application:UIApplication) {
        mainZApp?.activationTime = ZTime.Now()
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
        mainZApp?.activationTime = ZTime.Now()
        mainZApp?.HandleActivated(true)
        ZRecusivelyHandleActivation(activated:true)
    }
    
    static func RunApp() {
        UIApplicationMain(CommandLine.argc, convertArgs(CommandLine.unsafeArgv), nil, NSStringFromClass(ZAppController.self))
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        mainZApp?.HandleMemoryNearFull()
    }
}

private func convertArgs(_ args:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> UnsafeMutablePointer<UnsafeMutablePointer<Int8>>! {
    return UnsafeMutableRawPointer(args).bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc))
}


