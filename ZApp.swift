//
//  ZApp.swift
//  capsulefm
//
//  Created by Tor Langballe on /15/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit
import MediaPlayer

class ZApp : ZObject {
    static var appFile: ZFileUrl? = nil
    var activationTime = ZTime.Null
    var backgroundTime = ZTime.Null // -1 if not in background
    var startTime = ZTime.Now
    var startedCount = 0
    var oldVersion = 0.0

    var IsActive: Bool {
        return !activationTime.IsNull
    }

    var IsBackgrounded: Bool {
        return !backgroundTime.IsNull
    }

    static var Version: (String, Float, Int) { // version string, version with comma 1.2, build
        let bundle = Bundle.main
        if let sbuild = bundle.infoDictionary?["CFBundleVersion"] as? String,
            var sver = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
                sver = ZStrUtil.HeadUntil(sver, sep:"abc")
                if let build = Int(sbuild), let ver = Float(sver) {
                    return (sver, ver, build)
                }
        }
        return ("", 0, 0)
    }

    func GetRuntimeSecs() -> Double {
        return ZTime.Now - activationTime
    }
    
    func GetbackgroundTimeSecs() -> Double {
        return ZTime.Now - backgroundTime
    }
    
    override init() {
        activationTime = ZTime.Now
        super.init()
        mainZApp = self
    }

    func setVersions() { // this needs to be called by inheriting class, or strange stuff happens if called by ZApp
        let (_, ver, _) = ZApp.Version
        oldVersion = ZKeyValueStore.DoubleForKey("ZVerson")
        ZKeyValueStore.SetDouble(Double(ver), key:"ZVerson")
    }
    
    func EnableAudioRemote(_ command:ZAudioRemoteCommand, on:Bool) {
        let commandCenter = MPRemoteCommandCenter.shared()
        switch command {
        case .nextTrack:
            commandCenter.nextTrackCommand.isEnabled = on
        case .previousTrack:
            commandCenter.previousTrackCommand.isEnabled = on
        case .togglePlayPause:
            commandCenter.togglePlayPauseCommand.isEnabled = on
        default:
            break
        }
    }

    func HandleAppNotification(_ notification:ZNotification, action:String) { }
    func HandlePushNotificationWithDictionary(_ dict:[String:ZAnyObject], fromStartup:Bool, whileActive:Bool) { }
    func HandleLocationRegionCross(regionId:String, enter:Bool, fromAdd:Bool) { }
    func HandleMemoryNearFull() { }
    func HandleAudioInterrupted() { }
    func HandleAudioResume() { }
    func HandleAudioRouteChanged(_ reason:Int) { }
    func HandleAudioRemote(_ command:ZAudioRemoteCommand) {}
    func HandleRemoteAudioSeekTo(posSecs:Double) {}
    func HandleVoiceOverStatusChanged() { }
    func Main(_ args:[String]) { }
    func HandleBackgrounded(_ background:Bool) { }
    func HandleActivated(_ activated:Bool) { }
    func HandleOpenedFiles(_ files: [ZFileUrl], modifiers:Int) { }
    func ShowDebugText(_ str:String) { ZDebug.Print(str) }
    func HandleGotPushToken(_ token:String) { }
    func HandleLanguageBCPChanged(_ bcp:String) { }
    func HandleAppWillTerminate() { }
    func HandleShake() { }

    @discardableResult func HandleOpenUrl(_ url:ZUrl, showMessage:Bool = true, done:(()->Void)? = nil) -> Bool { return false }
}

var mainZApp : ZApp? = nil


