//
//  ZMotion.swift
//  capsulefm
//
//  Created by Tor Langballe on /24/10/17.
//  Copyright © 2017 Capsule.fm. All rights reserved.
//

private func didMove(_ n:Double, _ threshHold:Double) -> Bool {
    return abs(n) >= threshHold
}

import CoreMotion
class ZMotion {
    var manager = CMMotionManager()
    var old = Accelleration()
    struct Accelleration {
        var x = 0.0
        var y = 0.0
        var z = 0.0
    }

    func HandleMotion(intervalSecs:Double, minx: Double, miny: Double, minz: Double, handler:@escaping (_ a:Accelleration)->Void) {
    manager.accelerometerUpdateInterval = intervalSecs
        manager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if error != nil || data == nil {
                return
            }
            let a = data!.acceleration
            let ax = Accelleration(x:a.x, y:a.y, z:a.z)
            if didMove(self.old.x - a.x, minx) || didMove(self.old.y - a.y, miny) || didMove(self.old.z - a.z, minz) {
                handler(ax)
                self.old = ax
            }
        }
    }

    func StopMotion() {
        manager.stopAccelerometerUpdates()
    }
}


