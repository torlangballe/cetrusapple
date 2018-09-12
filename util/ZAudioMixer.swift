//
//  ZMediaMixer.swift
//  capsulefm
//
//  Created by Tor Langballe on /19/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import AVFoundation

// https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVFoundationFramework/index.html#//apple_ref/doc/uid/TP40008072
// https://developer.apple.com/library/prerelease/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/05_Export.html

@discardableResult func addTrackFromMediaItem(_ item:inout ZMediaItem, composition:AVMutableComposition, posSecs:Double, mixer:AVMutableAudioMix, background:Bool) -> Double {

    let track = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID:kCMPersistentTrackID_Invalid)
    //    let opts = [AVURLAssetPreferPreciseDurationAndTimingKey:1]

    if item.url.hasPrefix("file:") && !ZFileUrl(string:item.url).Exists() {
        ZDebug.Print("url file missing:", item.url)
    }
    var str = item.url
    if item.type == .speech {
        str = item.text
    }
    //    ZDebug.Print("*** mixaddtry:", str)

    var pos = max(0, posSecs - item.start.overlapSecs)

    //    ZDebug.Print("addingtrack:", item.service, item.url)
    if !item.service.isEmpty {
        item.start.absPosSecs = pos
        item.end.absPosSecs = pos
        return pos
    }
    let asset = AVURLAsset(url:URL(string:item.url)!) //, options:opts)
    let tracks = asset.tracks(withMediaType: AVMediaType.audio)
    if tracks.count == 0 {
        return posSecs
    }

    let mtrack = tracks[0]
    let range = mtrack.timeRange
    let s = pos + min(range.duration.seconds, item.start.cropSecs)
    var e = pos + max(0, range.end.seconds - item.end.cropSecs)

    if item.calculatedDuration == 0 {
        item.calculatedDuration = (e - s)
    } else {
        e = s + item.calculatedDuration
    }
    item.start.absPosSecs = s
    item.end.absPosSecs = e
    if item.background != background {
        return posSecs
    }
    
    let newRange = CMTimeRange(start:secsToCMTime(0), duration:secsToCMTime(item.calculatedDuration))
    do {
        if item.url.hasPrefix("file:") && !ZFileUrl(string:item.url).Exists() {
            ZDebug.Print("Doesn't exist!:", item.url)
        }
        
        try track?.insertTimeRange(newRange, of:mtrack, at:secsToCMTime(pos))
        let parameters = AVMutableAudioMixInputParameters(track:track)
        var sfd = item.start.fadeSecs
        var efd = item.end.fadeSecs
        let sf = pos + item.start.fadeSecs
        let ef = pos + item.calculatedDuration - item.end.fadeSecs
        if  sf > ef {
            let mid = (sf + ef) / 2
            sfd = mid - pos
            efd = pos + item.calculatedDuration - mid
        }
        parameters.setVolumeRamp(fromStartVolume: 0, toEndVolume:item.start.volume, timeRange:secsToCMRange(pos, duration:sfd))
        parameters.setVolumeRamp(fromStartVolume: item.end.volume, toEndVolume:0, timeRange:secsToCMRange(pos + item.calculatedDuration - efd, duration:efd))
        mixer.inputParameters.append(parameters)
        str = ZStr.Head(str, chars:30)
        //    ZDebug.Print("*** mixadd:", pos, item.calculatedDuration, str)
        pos += item.calculatedDuration - item.end.overlapSecs
        pos = max(pos, 0)
        return pos
    } catch {
        return pos
    }
}

// 3d: https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioEnvironmentNode_Class/index.html#//apple_ref/occ/cl/AVAudioEnvironmentNode

class ZAudioMixer : AVMutableAudioMix {
    func MixMediaItemsToFile(_ mediaItems:[ZMediaItem], outFile:ZFileUrl, async:Bool = true, done:@escaping (Error?,[ZMediaItem])->Void) {
        let start = ZTime.Now()
        var vmediaItems = mediaItems
        let (composition, mixer) = getMixerAndComponentsForMediaItems(&vmediaItems)
        //        ZDebug.Print("MixMediaItemsToFile comps:", composition.tracks.count)
        if composition.tracks.count == 0 {
            let file = ZFolders.GetFileInFolderType(.resources, addPath:"sound/silence.caf")
            if file.Exists() {
                var err:Error? = nil
                if !outFile.Exists() {
                    err = file.CopyTo(outFile)
                }
                done(err, vmediaItems)
            } else {
                done(ZNewError("Error copying silent audo file for empty media items"), vmediaItems)
            }
            return
        }
        //        if let exportSession = AVAssetExportSession(asset:composition, presetName:AVAssetExportPresetHighestQuality) { // AVAssetExportPresetAppleM4A
        if let exportSession = SDAVAssetExportSession(asset:composition) { // AVAssetExportPresetAppleM4A
            exportSession.audioMix = mixer;
            exportSession.outputFileType = AVFileType.m4a.rawValue // AVFileTypeQuickTimeMovie // AVFileTypeAIFF //
            exportSession.outputURL = outFile.url as URL?
            exportSession.audioSettings = [
                AVFormatIDKey: kAudioFormatMPEG4AAC, // kAudioFormatLinearPCM
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
//                AVLinearPCMIsBigEndianKey: false, //
//                AVLinearPCMIsFloatKey: false, //
//                AVLinearPCMBitDepthKey: 16,
//                AVLinearPCMIsNonInterleaved: false,
                AVEncoderBitRateKey: 128000,
            ]
            outFile.Remove()
            let downloadGroup = DispatchGroup()
            if !async {
                downloadGroup.enter()
            }
            exportSession.exportAsynchronously() { () in
                if exportSession.status == AVAssetExportSessionStatus.failed || outFile.DataSizeInBytes == 0 {
                    //!                    let (_, _) = getMixerAndComponentsForMediaItems(&vmediaItems) // this is just to debug
                }
                if exportSession.status != AVAssetExportSessionStatus.completed {
                    ZDebug.Print("************** MIXERROR!:", exportSession.error?.localizedDescription, exportSession.status.rawValue)
                    for m in vmediaItems {
                        if m.type == .audio {
                            ZDebug.Print("#####", m.local, m.url)
                        }
                    }
                    outFile.Remove()
                    done(exportSession.error as Error?, vmediaItems)
                } else {
                    if !outFile.Exists() {
                        let str = "Mixing: No file for successful mix: " + outFile.AbsString
                        ZDebug.Print(str)
                        done(ZNewError(str), vmediaItems)
                    } else {
                        ZDebug.Print("MixingTime Secs:", start.Since())
                        done(nil, vmediaItems)
                    }
                }
                if !async {
                    downloadGroup.leave()
                }
            }
            if !async && downloadGroup.wait(timeout: ZDispatchTimeInSecs(25)) == .timedOut {
                ZDebug.Print("Too Slow MixingTime Secs:", start.Since())
                for m in mediaItems {
                    if m.type == .audio && !m.local && !m.url.hasPrefix("file:") {
                        ZDebug.Print("Possible slow url:", m.url)
                    }

                }
                done(ZNewError("ZAudioMixer.MixMediaItemsToFile: timed out mixing."), vmediaItems)
            }
        }
    }
    
    var player:AVPlayer? = nil
    func PlayMixedMediaItems(_ mediaItems:[ZMediaItem]) {
        var mItems = mediaItems
        let (composition, mixer) = getMixerAndComponentsForMediaItems(&mItems)
        let playerItem = AVPlayerItem(asset:composition)
        playerItem.audioMix = mixer
        let player = AVPlayer(playerItem:playerItem)
        player.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let vc = change![.kindKey] as? Int {
            if keyPath == "staus" && vc == AVPlayerStatus.readyToPlay.rawValue {
                player?.removeObserver(self, forKeyPath:"status")
                player!.play()
            }
        }
    }
}

private func getMixerAndComponentsForMediaItems(_ mediaItems:inout [ZMediaItem]) -> (AVMutableComposition, AVMutableAudioMix) {
    let composition = AVMutableComposition()
    let mixer = AVMutableAudioMix()
    var backgroundItem = ZMediaItem()
    
    //    ZDebug.Print("*** mixadd: start *************************")

    mixer.inputParameters = []
    var pos = 0.0
    for (i, var m) in mediaItems.enumerated() {
        if m.type == .speech {
            if m.voice.type != .acapela {
                continue
            }
            //            let time = ZTime.Now()
            let error = m.RenderTextToTemporary()
            if error != nil {
                mainZApp?.ShowDebugText("getMixerAndComponentsForMediaItems:Error rendering text: " + m.processedText + ": " + error!.localizedDescription)
                continue
            }
            //            ZDebug.Print("rendered text in:", (ZTime.Now() - time), "for:", m.text)
        }
        assert(!m.url.isEmpty)
        pos = addTrackFromMediaItem(&m, composition:composition, posSecs:pos, mixer:mixer, background:false)
        if m.background || i == mediaItems.count - 1 {
            if backgroundItem.type != .none {
                backgroundItem.end.absPosSecs = pos
                backgroundItem.calculatedDuration = (backgroundItem.end.absPosSecs - backgroundItem.start.absPosSecs)
                if backgroundItem.calculatedDuration > 0 {
                    addTrackFromMediaItem(&backgroundItem, composition:composition, posSecs:backgroundItem.start.absPosSecs, mixer:mixer, background:true)
                }
            }
            backgroundItem = m
            backgroundItem.start.absPosSecs = pos
        }
        mediaItems[i] = m
        //        ZDebug.Print("mediaItem:", m.id, m.start.absPosSecs, m.end.absPosSecs, m.text, m.url)
    }
    return (composition, mixer)
}

private func secsToCMTime(_ seconds:Double) -> CMTime {
    return CMTime(seconds:seconds, preferredTimescale:600)
}

private func secsToCMRange(_ start:Double, duration:Double) -> CMTimeRange {
    return CMTimeRange(start:secsToCMTime(start), duration:secsToCMTime(duration))
}

