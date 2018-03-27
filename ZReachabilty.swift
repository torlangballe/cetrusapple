//
//  ZAddressReachabilty.swift
//  Cetrus
//
//  Created by Tor Langballe on /26/11/15.
//

import Foundation
import SystemConfiguration
import CoreTelephony

class ZReachabilty : NSObject {
    let reacher = Reachability()
    var reachable = false
    var cellularOnly = true
    
    @discardableResult func Start(onMain:Bool = true, got:((_ reachable:Bool, _ cellularOnly:Bool)->Void)? = nil) -> Error? {
        reacher?.whenReachable = { [weak self] reachability in
            self?.cellularOnly = (reachability.connection != .wifi)
            self?.reachable = true
            if got != nil {
                if onMain {
                    ZMainQue.async {
                        got!(true, self?.cellularOnly ?? true)
                    }
                } else {
                    got!(true, self?.cellularOnly ?? true)
                }
            }
        }
        reacher?.whenUnreachable = { [weak self] reachability in
            self?.reachable = false
            if got != nil {
                if onMain {
                    ZMainQue.async {
                        got!(false, false)
                    }
                } else {
                    got!(false, false)
                }
            }
        }
        do {
            try reacher?.startNotifier()
        } catch let error {
            return error
        }
        return nil
    }
}

