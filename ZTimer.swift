//
//  ZTimer.swift
//  Zed
//
//  Created by Tor Langballe on /18/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZDispatchQueue = DispatchQueue

class ZTimerBase : NSObject {
    weak var nsTimer:Timer? = nil

    deinit {
        Stop()
    }
    
    func Stop() {
        nsTimer?.invalidate()
        nsTimer = nil
    }
    
    var Valid: Bool {
        return nsTimer != nil
    }
}

protocol ZTimerOwner {
    //    var timers: [ZTimerBase] { get set }
    //mutating func AddTimer(timer:ZTimerBase)
}

class ZRepeater : ZTimerBase {
    var closure:(()->Bool)? = nil

    func Set(_ secs:Double, owner:ZTimerOwner? = nil, now:Bool = false, done:@escaping ()->Bool) {
        Stop()
        if now {
            if !done() {
                return
            }
        }
        closure = done
        nsTimer = Timer.scheduledTimer(timeInterval: TimeInterval(secs), target:self, selector:#selector(ZRepeater.repeatTimerFired(_:)), userInfo:nil, repeats:true)
    }

    @objc func repeatTimerFired(_ timer:Timer) {
        if !closure!() {
            Stop()
        }
    }
    
}

class ZTimer : ZTimerBase {
    var closure:(()->Void)? = nil
    
    func Set(_ secs:Double, owner:ZTimerOwner? = nil, done:@escaping ()->Void) {
        Stop()
        //        owner?.AddTimer(self)
        closure = done
        nsTimer = Timer.scheduledTimer(timeInterval: TimeInterval(secs), target:self, selector:#selector(ZTimer.timerFired(_:)), userInfo:nil, repeats:false)
    }

    @objc func timerFired(_ timer:Timer) {
        Stop()
        closure!()
    }
    
    static func Sleep(secs:Double) {
        usleep(useconds_t(secs * 1000000))
    }
}

class _ZBlocker : NSObject {
    var block:()->Void
    init(block:@escaping ()->Void) {
        self.block = block
    }
}

extension NSObject {
    func PerformAfterDelay(_ afterDelay:Float, _ block:@escaping ()->Void) {
        let blocker = _ZBlocker(block:block)
        self.perform(#selector(NSObject.fireBlockAfterDelay(_:)), with:blocker, afterDelay:TimeInterval(afterDelay))
    }
    @objc func fireBlockAfterDelay(_ blocker:_ZBlocker) {
        blocker.block()
    }
}

func ZDispatchTimeInSecs(_ secs:Double) -> DispatchTime {
    return DispatchTime.now() + Double(Int64(secs) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
}

typealias ZOperationQueue = OperationQueue // not used...

var ZMainQue: DispatchQueue {
    return DispatchQueue.main
}

var ZBackgroundParallellQue: DispatchQueue {
    return DispatchQueue(label:"ZBackgroundParallellQue") 
}

var queues = [String:DispatchQueue]()
func ZGetBackgroundSerialQueue(_ name:String) -> DispatchQueue {
    if let que = queues[name] {
        return que
    }
    let (ver, _, _) = ZApp.Version
    let que = DispatchQueue(label: ver + "." + name, attributes: [])
    queues[name] = que
    return que
}

