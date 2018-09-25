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

class ZRepeater : ZTimerBase {
    var closure:(()->Bool)? = nil

    func Set(_ secs:Double, now:Bool = false, done:@escaping ()->Bool) {
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
    
    func Set(_ secs:Double, done:@escaping ()->Void) {
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

class zTimerPerformer : NSObject {
    var blocker: _ZBlocker? = nil
    
    @objc func fireBlockAfterDelay(_ blocker:_ZBlocker) {
        blocker.block()
    }
}

func ZPerformAfterDelay(_ afterDelay:Double, _ block:@escaping ()->Void) {
    let o = zTimerPerformer()
    o.blocker = _ZBlocker(block:block)
    o.perform(#selector(zTimerPerformer.fireBlockAfterDelay(_:)), with:o.blocker, afterDelay:TimeInterval(Float(afterDelay)))
}

func ZDispatchTimeInSecs(_ secs:Double) -> DispatchTime {
    return DispatchTime.now() + Double(Int64(secs) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
}

var ZMainQue: DispatchQueue {
    return DispatchQueue.main
}

var queCount = 1

var queues = [String:DispatchQueue]()
func ZGetBackgroundQue(name:String? = nil, serial:Bool = false) -> DispatchQueue {
    var n = ""
    if name == nil {
        n = "Que.\(queCount)"
        queCount += 1
    } else {
        n = name!
    }
    if let que = queues[n] {
        return que
    }
    let (ver, _, _) = ZApp.Version
    let que = DispatchQueue(label: ver + "." + n, attributes:serial ? [] : .concurrent)
    queues[n] = que
    return que
}

