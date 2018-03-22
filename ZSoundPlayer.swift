//
//  ZSoundPlayer.swift
//  Zed
//
//  Created by Tor Langballe on /25/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import MediaPlayer

enum ZAudioRemoteCommand {
    case none, play, pause, stop, togglePlayPause, nextTrack, previousTrack,
        beginSeekingBackward, endSeekingBackward, beginSeekingForward, endSeekingForward
}

class ZSoundPlayer: NSObject, AVAudioPlayerDelegate {
    var done:(()->Void)? = nil
    fileprivate var loop = false
    var audioPlayer:AVAudioPlayer? = nil
    static var lastPlayer: AVAudioPlayer? = nil
    static var current: ZSoundPlayer? = nil
    
    func audioPlayerDidFinishPlaying(_ myaudio:AVAudioPlayer, successfully:Bool) {
        ZSoundPlayer.current = nil
        if loop {
            audioPlayer?.play()
        } else {
            done?()
        }
    }
    
    func PlayUrl(_ url:String, volume:Float = -1, loop:Bool = false, stopLast:Bool = true, done:(()->Void)? = nil) {
        var vurl = url
        if !vurl.hasPrefix("file:") {
            let file = ZFolders.GetFileInFolderType(.resources, addPath:"sound/" + vurl)
            if file.Exists() {
                vurl = String(describing:file.url!)
            } else {
                done?()
                return
            }
        }
        if stopLast {
            ZSoundPlayer.StopLastPlayedSound()
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf:ZUrl(string:vurl).url! as URL)
        } catch let error {
            ZDebug.Print("sound playing error:", error.localizedDescription, ZFileUrl(string:vurl).DataSizeInBytes, vurl)
        }
        if volume != -1 {
            audioPlayer?.volume = volume
        }
        ZDebug.Print("Play Audio:", url)
        audioPlayer?.play()
        ZSoundPlayer.lastPlayer = audioPlayer

        if done != nil || loop {
            ZSoundPlayer.current = self
            self.done = done
            self.loop = loop
            audioPlayer?.delegate = self
            if !audioPlayer!.play() {
                ZDebug.Print("audioPlayer play failed")
                return
            }
        }
    }
    
    func Stop() {
        done?()
        audioPlayer?.stop()
    }

    static func StopLastPlayedSound() {
        ZSoundPlayer.lastPlayer?.stop()
    }

    static func SetCurrentTrackPos(_ pos:Double, duration:Double) {
        ZMainQue.async {
            var songInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String : Any]()
            songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = pos as Any
            songInfo[MPMediaItemPropertyPlaybackDuration] = duration as Any
            songInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 as Any
            MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
        }
    }

    static func SetCurrentTrackPlayingMetadata(_ image:ZImage?, title:String, album:String = "", pos:Double? = nil) {
        ZMainQue.async {
            var songInfo = [String:AnyObject]()
            if image != nil {
                let imageArtwork = MPMediaItemArtwork.init(boundsSize:image!.size) { (size) in
                    return image!.GetScaledInSize(ZSize(size)) ?? image!
                }
                songInfo[MPMediaItemPropertyArtwork] = imageArtwork
            }
            songInfo[MPMediaItemPropertyTitle] = title as AnyObject?
            if !album.isEmpty {
                songInfo[MPMediaItemPropertyAlbumTitle] =  album as AnyObject?
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
        }
    }
    
    static func Vibrate() {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    }
}
