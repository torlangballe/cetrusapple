//
//  ZAudioSession.swift
//  Zed
//
//  Created by Tor Langballe on /21/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit
import AVFoundation

struct ZAudioSession {
    @discardableResult static func SetAppIsPlayingSound(_ isPlaying:Bool = true, mixWithOthers:Bool = false) -> Error? {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        do {
            if isPlaying {
                let aus = AVAudioSession.sharedInstance()
                if mixWithOthers { 
                    try aus.setCategory(AVAudioSessionCategoryPlayback, with:.mixWithOthers)
                } else {
                    try aus.setCategory(AVAudioSessionCategoryPlayback)
                }
                try aus.setPreferredSampleRate(44100)
            }
            try AVAudioSession.sharedInstance().setActive(isPlaying)
        } catch let error as NSError {
            return error
        }
        return nil
    }
}
