//
//  ZResource.swift
//  capsulefm
//
//  Created by Tor Langballe on /11/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

var list = [ZResource]()

// NSBundleOnDemandResourceExceededMaximumSizeError: 4993
// NSBundleOnDemandResourceInvalidTagError: 4994
// NSBundleOnDemandResourceOutOfSpaceError: 4992

@available(iOS 9.0, *)
class ZResource: NSBundleResourceRequest, ZTimerOwner {
    var sid = ""
    var done = false
    let timer = ZTimer()

    deinit {
        ZDebug.Print("ZResource.deinit:", sid, tags)
    }
    
    func BeginAccessing(got:@escaping (_ error:Error?)->Void) {
        ZDebug.Print("ZResource.BeginAccessing:", sid, self.tags)
        done = false
        self.bundle.setPreservationPriority(1, forTags:self.tags)
        self.conditionallyBeginAccessingResources{ [weak self] (ready) in
            if ready {
                self?.done = true
                self!.addToList(self!)
                ZDebug.Print("ZResource.BeginAccessing. ready conditionally.", self!.sid, self!.tags)
                ZMainQue.async { () in
                    got(nil)
                }
                return
            } else {
                ZDebug.Print("ZResource.BeginAccessing. NOT ready conditionally.", self!.sid, self!.tags)
            }
            self!.timer.Set(5, owner:self) { () in
                if self != nil {
                    ZDebug.Print("ZResource still getting:", self!.progress.fractionCompleted, self!.sid, self!.tags)
                }
            }
            self!.beginAccessingResources() { (error) in
                if error != nil {
                    self!.endAccessingResources()
                }
                if error == nil {
                    self!.addToList(self!)
                }
                ZDebug.Print("ZResource.Done BeginAccessing.", error?.localizedDescription ?? "", self!.sid, self!.tags)
                ZMainQue.async { () in
                    self?.timer.Stop()
                    self?.done = true
                    got(error)
                }
            }
        }
    }
    
    func addToList(_ r:ZResource) {
        if list.index(where: { $0.sid == r.sid }) == nil {
            list.append(r)
        }
    }
    
    func ConditionallyBeginAccessing(_ got:@escaping (_ ready:Bool)->Void) {
        done = false
        self.conditionallyBeginAccessingResources() { (ready) in
            if ready {
                self.done = true
            }
            ZMainQue.async { () in
                got(ready)
            }
        }
    }
    
    var FractionCompleted: Float {
        if done {
            //            ZDebug.Print("ZResource.FractionCompleted done:", sid)
            return -1
        }
        return Float(self.progress.fractionCompleted)
    }
    
    func Unuse() {
        list.removeIf { $0.sid == sid }
        ZDebug.Print("ZResource.Unuse:", sid, self.tags)
        self.endAccessingResources()
    }
}

