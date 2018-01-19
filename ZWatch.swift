//
//  ZWatch.swift
//  Zed
//
//  Created by Tor Langballe on /25/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import WatchConnectivity

protocol ZWatchDelegate {
    @discardableResult func HandleWatchMessage(_ values:[String:AnyObject]) -> Bool

}

class ZWatch: ZObject, WCSessionDelegate {
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
    
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    static var zdelegate: ZWatchDelegate? = nil
    static func SendToWatch(_ values:[String:AnyObject]) {
    }
    
    @available(iOS 9.0, *)
    func session(_ session:WCSession, didReceiveMessage:[String: Any]) {
        ZDebug.Print("WCSession::didReceiveMessage");
        ZMainQue.async { () in
            ZWatch.zdelegate!.HandleWatchMessage(didReceiveMessage as [String : AnyObject])
        }
    }
    
    static func IsConnected(activate:Bool) -> Bool {
        if WCSession.isSupported() { // check if the device support to handle an Apple Watch
            let session = WCSession.default
            session.delegate = mainWatch
            var state = session.activationState
            if state != .activated && activate {
                session.activate()
                state = session.activationState
                if state != .activated {
                    return false
                }
            }
            //            session.delegate = mainWatch            
            if session.isPaired { // Check if the iPhone is paired with the Apple Watch
                return true
            }
        }
        return false
    }
}

var mainWatch = ZWatch()

