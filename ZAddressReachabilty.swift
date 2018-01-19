//
//  ZAddressReachabilty.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import SystemConfiguration
import CoreTelephony

class ZAddressReachabilty : ZObject {
    var reachable = true
    
    init(address:String) {
    }
    func DoTimer(_ on:Bool) {
    }
}

// http://stackoverflow.com/questions/30743408/check-for-internet-conncetion-in-swift-2-ios-9
/*
    var ref:SCNetworkReachabilityRef
    var saddress = ""
    var reachable = -1
    var wifi = -1
    var wwan = -1
    var timer:ZTimer? = nil
    
    init(address:String) {
        ref = SCNetworkReachabilityCreateWithName(kCFAllocatorSystemDefault, (address as NSString).UTF8String).takeRetainedValue()
    }
    
    deinit {
        SCNetworkReachabilityUnscheduleFromRunLoop(ref, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)
    }

    private func getReachabiltyFromFlags(flags:SCNetworkReachabilityFlags) {
        let rawFlags = flags.rawValue
        reachable = Int(rawFlags & SCNetworkReachabilityFlags.Reachable.rawValue) != 0 ? 1 : 0
        if Int(flags.rawValue & (SCNetworkReachabilityFlags.InterventionRequired.rawValue | SCNetworkReachabilityFlags.ConnectionRequired.rawValue)) != 0 { // kSCNetworkReachabilityFlagsTransientConnection
            reachable = 0
        }
        wwan = 0
        wifi = 0
        if (rawFlags & SCNetworkReachabilityFlags.Reachable.rawValue) != 0 {
            return
        }
        
        if (rawFlags & SCNetworkReachabilityFlags.ConnectionRequired.rawValue) == 0 {
            wifi = 1
        }
        
        if (rawFlags & SCNetworkReachabilityFlags.ConnectionOnDemand.rawValue) != 0 || (rawFlags & SCNetworkReachabilityFlags.ConnectionOnTraffic.rawValue) != 0 {
            if (rawFlags & SCNetworkReachabilityFlags.InterventionRequired.rawValue) == 0 {
            wifi = 1
        }
        // ios:
        if (rawFlags & SCNetworkReachabilityFlags.IsWWAN.rawValue) == SCNetworkReachabilityFlags.IsWWAN.rawValue {
            wifi = 0
            wwan = 1
        }
    }
    
    func DoTimer(on:Bool) {
        if(on) {
            timer = SetTimer(2.7) {
            }
        } else {
            timer.Stop()
        }
    }
}

    func SetPoll() -> Bool {

        var context = SCNetworkReachabilityContext()

        let block: @convention(block) (SCNetworkReachabilityRef, SCNetworkReachabilityFlags, UnsafePointer<Void>) -> Void = {
            (reachability: SCNetworkReachabilityRef, flags: SCNetworkReachabilityFlags, data: UnsafePointer<Void>) in
            // do something here
        }
        
        let blockObject = imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
        let fp = unsafeBitCast(blockObject, SCNetworkReachabilityCallBack.self)
        var ok = SCNetworkReachabilitySetCallback(reachability!, fp, &context) == 1
        
            if SCNetworkReachabilityScheduleWithRunLoop(reachability!, CFRunLoopGetCurrent(), NSDefaultRunLoopMode) == 0 {
        
        ok = SCNetworkReachabilitySetCallback((SCNetworkReachabilityRef)ref, addressReachableCallback, &context);
        if(ok)
        ok = SCNetworkReachabilityScheduleWithRunLoop((SCNetworkReachabilityRef)ref, ::CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        if(!ok)
        {
            //      ::CFRelease((SCNetworkReachabilityRef)ref);
            ref = NULL;
        }
        return ok
    }
}

int ZAddressReachabilty::Event(int evtype, void *data, ZMSGTYPE msg)
{
    SCNetworkReachabilityFlags flags;
    
    if(evtype == EV_TIMER)
    {
        if(::SCNetworkReachabilityGetFlags((SCNetworkReachabilityRef)ref, &flags))
        getReachabiltyFromFlags(flags);
        return 3145;
    }
    return true;
}

*/
