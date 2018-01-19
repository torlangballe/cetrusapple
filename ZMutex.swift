//
//  ZMutex.swift
//  capsulefm
//
//  Created by Tor Langballe on /11/12/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation

class ZMutex {
    var lock = pthread_mutex_t()

    init() {
        let _ = pthread_mutex_init(&lock, nil)
    }
    
    func Lock() {
        pthread_mutex_lock(&lock)
    }

    func Unlock() {
        pthread_mutex_unlock(&lock)
    }
}
