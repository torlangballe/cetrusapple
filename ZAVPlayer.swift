//
//  ZAVPlayer.swift
//  Zed
//
//  Created by Tor Langballe on /21/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

private var kAVPlayerItemKVOContext = 0

protocol ZAVPlayerDelegate {
    func HandleAVPlayerError(_ player:ZAVPlayer)
    func HandleAVPlayerStateUpdated(_ player:ZAVPlayer)
    func HandleAVPlayerFinishedPlaying(_ player:ZAVPlayer)
    func HandleAVPlayerLostToken(_ player:ZAVPlayer)
    func HandleAVPlayerNewAccessLogEntry(_ player:ZAVPlayer)
    func HandleAVPlayerFailedToPlayToEndTime(_ player:ZAVPlayer)
    func HandleAVPlayerNewErrorLogEntry(_ player:ZAVPlayer)
    func HandleAVPlayerPlaybackStalled(_ player:ZAVPlayer)
    func HandleAVPlayerNeedsRebuilding(_ player:ZAVPlayer)
}

class ZAVPlayer : AVQueuePlayer, DZRPlayerDelegate, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate, ZTimerOwner {
    
    struct Fade {
        var time = ZTime.Null
        var volume = 0.0
    }
    var fadeStart = Fade()
    var fadeEnd = Fade()
    var timers = [ZTimerBase]()
    var subPlayer: AnyObject? = nil
    var streamSeekToSeconds = 0.0
    
    enum PlayerType:Int { case none, file, url, spotify, wimp, soundcloud, deezer, iPodlib, appleMusic, beats, napster }
    
    var type = PlayerType.none
    var trackUrl = ZUrl()
    var checkTimer = ZRepeater()
    var fadeTimer = ZRepeater()
    var timeObserver:AnyObject? = nil
    var getLevelMetering = false
    var metaObserving = false
    var leftMeterLevel = 0.0
    var rightMeterLevel = 0.0
    var handler:ZAVPlayerDelegate? = nil
    var service: PService
    //    var mimiAudioTapReader : MimiAudioTapReader? = nil
    //    var oldMimiTapReader : MimiAudioTapReader? = nil

    struct Deezer {
        var player:DZRPlayer? = nil
        var requestManager = DZRRequestManager()
        var trackRequest: DZRNetworkRequest? = nil
        var stopping = false
        var gettingTrack = false
        var playing = false
    }
    var deezer = Deezer()

    struct Spotify {
        var position = 0.0
        var playing = false
        var manager: SPTAudioStreamingController? = nil
    }
    var spotify = Spotify()

    
    required init(useObserver:Bool = true, streaming:Bool = false) {
        service = PService()
        super.init()
        self.automaticallyWaitsToMinimizeStalling = false
        self.actionAtItemEnd = AVPlayerActionAtItemEnd.pause
        if useObserver {
            if queOrg == nil {
                queOrg = QueueOrganizer()
                addObs(queOrg!, selector:#selector(QueueOrganizer.itemFinishedPlaying(_:)), notification:NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue) // this
                addObs(queOrg!, selector:#selector(QueueOrganizer.itemPlaybackStalled(_:)), notification:NSNotification.Name.AVPlayerItemPlaybackStalled.rawValue)  // and this were called on current item, but testing without
                addObs(queOrg!, selector:#selector(QueueOrganizer.itemNewAccessLogEntry(_:)), notification:NSNotification.Name.AVPlayerItemNewAccessLogEntry.rawValue)
                addObs(queOrg!, selector:#selector(QueueOrganizer.itemNewErrorLogEntry(_:)), notification:NSNotification.Name.AVPlayerItemNewErrorLogEntry.rawValue)
                addObs(queOrg!, selector:#selector(QueueOrganizer.itemFailedToPlayToEndTime(_:)), notification:NSNotification.Name.AVPlayerItemFailedToPlayToEndTime.rawValue)
            }
            queOrg!.players.append(self)
            addObserver(self, forKeyPath:"status", options:NSKeyValueObservingOptions(), context:nil)
            addObserver(self, forKeyPath:"rate", options:NSKeyValueObservingOptions(), context:nil)
            if streaming {
                addObserver(self, forKeyPath:"currentItem.status", options:NSKeyValueObservingOptions(rawValue: 0), context:&kAVPlayerItemKVOContext)
                addObserver(self, forKeyPath:"currentItem.playbackLikelyToKeepUp", options:NSKeyValueObservingOptions(rawValue: 0), context:&kAVPlayerItemKVOContext)
            }
        }
    }
    
    deinit {
        self.removeObserver(self, forKeyPath:"rate") // this fails if none there, slow but easier than remembering
        self.removeObserver(self, forKeyPath:"status") // this fails if none there, slow but easier than remembering
        self.removeObserver(self, forKeyPath:"currentItem.status") // this fails if none there, slow but easier than remembering

        for t in timers {
            t.Stop()
        }
        timers.removeAll()
    }
    
    private func handleStalled() {
        if self.currentItem!.isPlaybackLikelyToKeepUp ||
            (self.availableDuration() - CMTimeGetSeconds(self.currentItem!.currentTime())) > 10.0 {
            self.play()
        } else {
            self.PerformAfterDelay(0.5) {
                self.handleStalled()
            }
        }
    }
    
    private func availableDuration() -> Double {
        let loadedTimeRanges = self.currentItem!.loadedTimeRanges
        let timeRange = loadedTimeRanges[0].timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + durationSeconds
        return result
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        //        if context == &ItemMetadataContextt {
        //            handler.HandleGotnewmetadata(self)
        //            return
        //        }
        
        //!!!        let player = object as! ZAVPlayer
//        if keyPath == "mimifail" && mimiAudioTapReader != nil {
//            ZDebug.Print("MimiFail: Disabling")
//            installMimiTap(false)
//        }
        if keyPath == "rate" && self.currentItem != nil {
            if self.rate == 0 && //if player rate dropped to 0
                self.currentItem!.currentTime() > kCMTimeZero &&
                self.currentItem!.currentTime() < self.currentItem!.duration && IsPlaying() {
                    if self.currentItem!.isPlaybackLikelyToKeepUp || //
                        self.availableDuration() - CMTimeGetSeconds(self.currentItem!.currentTime()) > 10.0 {
                        self.play()
                    } else {
                        handleStalled()
                    }
            }
        }
        if keyPath == "status" {
            if object is ZAVPlayer {
                if status == AVPlayerStatus.failed {
                    ZDebug.Print("------------------ Player Error: \(String(describing: error))")
                    if self.timeObserver != nil {
                        self.removeTimeObserver(timeObserver!)
                    }
                    self.removeObserver(self, forKeyPath:"status")
                    removeObserverFromQue(NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue)
                    removeObserverFromQue(NSNotification.Name.AVPlayerItemPlaybackStalled.rawValue)
                    removeObserverFromQue(NSNotification.Name.AVPlayerItemNewAccessLogEntry.rawValue)
                    removeObserverFromQue(NSNotification.Name.AVPlayerItemNewErrorLogEntry.rawValue)
                    //  self.init(useObserver:true) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    handler!.HandleAVPlayerError(self)
                    handler!.HandleAVPlayerNeedsRebuilding(self)
                }
            }
            return
        }
        if context == &kAVPlayerItemKVOContext && object is ZAVPlayer && keyPath == "currentItem.playbackLikelyToKeepUp" {
            if streamSeekToSeconds != 0 {
                self.volume = 0
            }
        }
        if context == &kAVPlayerItemKVOContext && object is ZAVPlayer && keyPath == "currentItem.status" {
//            if cPlayer.mimiInfo.inited {
//                if type == .spotify && currentItem?.status == .readyToPlay {
//                    ZAudioSession.SetAppIsPlayingSound()
//                }
//                if currentItem?.status == .readyToPlay && (type == .wimp || type == .appleMusic || type == .soundcloud || type == .iPodlib) {
//                    installMimiTap()
//                } else {
//                    installMimiTap(false)
//                }
//                handler!.HandleAVPlayerStateUpdated(self)
//            }
            if type == .url {
                if currentItem?.status == .failed {
                    ZDebug.Print("Failed to play streaming url:", self.trackUrl.AbsString)
                    handler!.HandleAVPlayerError(self)
                } else if currentItem?.status == .readyToPlay {
                    if streamSeekToSeconds != 0 {
                        self.SeekToSecs(streamSeekToSeconds)
                        self.FadeToVolume(1, durationSecs:1)
                        self.streamSeekToSeconds = 0
                    }
                    self.Play()
                }
            }
        }
    }
    
    // http://stackoverflow.com/questions/19370752/how-to-get-unprepare-and-finalize-callbacks-to-fire-for-multiple-mtaudioprocessi
    // http://stackoverflow.com/questions/19202306/how-do-you-release-an-mtaudioprocessingtap
/*
    func installMimiTap(_ on:Bool = true) {
        if on {
            if mimiAudioTapReader == nil {
                if let m = MimiAudioTapReader.create(with:currentItem) {
                    m.addObserver(self, forKeyPath:"mimifail", context:nil)
                    //                    print(String(format:"------------------------- INSTALL MIMI curitem:%p tap:%p", unsafeBitCast(currentItem, to:Int.self), unsafeBitCast(m, to:Int.self)))
                    mimiAudioTapReader = m
                    cPlayer.mimiInfo.UpdateAudioTaps(intensityOnly:false)
                }
            }
        } else {
            //            print(String(format:"************************** UNINSTALL MIMI atr:%p ci:%p am:%p", unsafeBitCast(mimiAudioTapReader, to:Int.self), unsafeBitCast(currentItem, to:Int.self), unsafeBitCast(currentItem?.audioMix, to:Int.self)))
            if mimiAudioTapReader != nil {
                mimiAudioTapReader!.removeObserver(self, forKeyPath:"mimifail", context:nil)
                oldMimiTapReader = mimiAudioTapReader
            }
            mimiAudioTapReader = nil
            currentItem?.audioMix = nil
        }
    }
*/
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error:Error!) {
        //    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didFailToPlayTrack trackUri: URL!) {
        ZDebug.Print("SPTAudioStreamingController.didReceiveError:", error.localizedDescription)
        ClearMeter()
        handler?.HandleAVPlayerError(self)
    }
/*
    func audioStreamingDidLosePermissionForPlayback(audioStreaming:SPTAudioStreamingController) {
        ClearMeter()
        handler?.HandleAVPlayerNewErrorLogEntry(self)
    }
  */
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition:TimeInterval) {
        spotify.position = Double(didChangePosition)
    }

    internal func audioStreamingDidDisconnect(_ audioStreaming: SPTAudioStreamingController!) {
        ZDebug.Print("Spotify audioStreamingDidDisconnect")
    }
    
    internal func audioStreamingDidReconnect(_ audioStreaming: SPTAudioStreamingController!) {
        ZDebug.Print("Spotify audioStreamingDidReconnect")
    }

    internal func audioStreamingDidEncounterTemporaryConnectionError(_ audioStreaming: SPTAudioStreamingController!) {
        ZDebug.Print("Spotify audioStreamingDidEncounterTemporaryConnectionError")
    }

    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        spotify.playing = isPlaying
//        if isPlaying && cPlayer.mimiInfo.useSpotify {
//            MMDemoAudioController.shared().start()
//            ZAudioSession.SetAppIsPlayingSound()
//        }
        ClearMeter()
    //    ZDebug.Print(format:"Spotify DidPlay:%d",isPlaying)
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack:String) {
        ClearMeter()
        handler!.HandleAVPlayerFinishedPlaying(self)
    }
    
    // Deezer:

    func player(_ player: DZRPlayer!, didBuffer bufferedBytes: Int64, outOf totalBytes: Int64) {
        //       ZDebug.Print("Deezer:didBuffer:", bufferedBytes, "of", totalBytes)
    }

    func player(_ player: DZRPlayer!, didPlay playedBytes: Int64, outOf totalBytes: Int64) {
        if !deezer.playing {
            deezer.playing = true
            handler!.HandleAVPlayerStateUpdated(self)
        }
        //        ZDebug.Print("Deezer:didPlay:", playedBytes, "of", totalBytes)
    }

    func player(_ player: DZRPlayer!, didStartPlaying track: DZRTrack!) {
        var sent = false
        if track == nil {
            self.ClearMeter()
            if !deezer.stopping {
                handler!.HandleAVPlayerFinishedPlaying(self)
                sent = true
            }
            if deezer.trackRequest != nil {
                deezer.trackRequest!.cancel()
                deezer.player!.stop()
                deezer.player?.play(nil)
            }
            deezer.stopping = false
            deezer.playing = false
        } else {
            deezer.playing = true
        }
        if !sent {
            handler!.HandleAVPlayerStateUpdated(self)
        }
    }
    
    func player(_ player: DZRPlayer!, didEncounterError error: Error!) {
        ClearMeter()
        handler!.HandleAVPlayerError(self)
    }
    
    func playerDidPause(_ player: DZRPlayer!) {
        deezer.playing = false
        handler!.HandleAVPlayerStateUpdated(self)
    }
    
    func InitDeezer()
    {
        deezer.stopping = false
        deezer.gettingTrack = false
        deezer.player?.stop()
        deezer.player = nil
        deezer.player = DZRPlayer(connection:cApp.deezer.session)
        if deezer.player != nil {
            deezer.player!.delegate = self
            deezer.player!.networkType = DZRPlayerNetworkType.wifiAnd3G
            deezer.requestManager = DZRRequestManager.default().sub()
            deezer.requestManager.dzrConnect = cApp.deezer.session
            deezer.trackRequest = nil
        }
    }
    
    func InvalidateDeezer()
    {
        deezer.player = nil
        deezer.requestManager = DZRRequestManager()
        deezer.trackRequest!.cancel()
        deezer.trackRequest = nil
    }
    
// deezer over

    // Spotify:
    
    func InitSpotify(_ provider:Provider, afterLogin:Bool) {
        if spotify.manager != nil {
            spotify.manager!.logout()
        }
        
        spotify.manager = SPTAudioStreamingController.sharedInstance() // clientId:cApp.spotify.clientId)
        //        let s = cPlayer.mimiInfo.useSpotify ? MMDemoAudioController.shared().sptAudioController : SPTCoreAudioController()
        let s = SPTCoreAudioController()
        if !spotify.manager!.loggedIn {
            do {
                try spotify.manager!.start(withClientId:cApp.spotify.clientId, audioController:s, allowCaching:false)
            } catch let error as NSError {
                ZDebug.Print("init spotify manager failed:", error)
            }
        }
        //        spotify.manager!.diskCache = SPTDiskCache(capacity:1024 * 1024 * 64)
        
        spotify.manager!.delegate = self
        spotify.manager!.playbackDelegate = self
        spotify.manager!.diskCache = nil
        let token = provider.Token
        spotify.manager!.setRepeat(.off) { (error) in
            self.spotify.manager!.login(withAccessToken:token)
        }
        /*
            if error != nil {
                if afterLogin {
                    ZAlert.Say(String(describing: error))
                    cApp.spotify.InvalidateProviderAndPush(prov)
                }
            }
        }
         */
    }

    func AllowExternalPlayback(_ on:Bool) {
        self.allowsExternalPlayback = on
    }
    

    func IsPlaying() -> Bool {
        switch type {
        case .spotify:
            return (spotify.manager?.metadata != nil && spotify.playing) // currentTrackMetadata
            
        case .deezer:
            return deezer.player!.isPlaying() || deezer.gettingTrack
            
        case .napster, .appleMusic:
            return service.IsPlaying()
            
        default:
            //            let s = self.currentItem.status
            if self.items().count == 0 {
                return false
            }
            return self.rate != 0.0
        }
    }
    
    func Play()
    {
        var path = ""
        var fspec = ZFileUrl()
      
        ZDebug.Print("*********** ZAVPLayer.Play:", getPlayerType(type))
        if type != .file {
            checkTimer.Set(0.5, owner:self) { () in
                if self.currentItem != nil && self.currentItem!.status == AVPlayerItemStatus.failed {
                    self.handler!.HandleAVPlayerError(self)
                    return false
                }
                return true
            }
        }
        if !trackUrl.IsEmpty {
            if type == .file {
                fspec = ZFileUrl(url:trackUrl)
                path = fspec.GetName()
                if !fspec.Exists() {
                    ZDebug.Print("************* ZAVPlayer::erroring on missing file: " + path)
                    handler!.HandleAVPlayerError(self)
                    return
                }
            } else {
                path = trackUrl.ResourcePath
                if path.isEmpty {
                    path = trackUrl.AbsString
                }
            }
            ZDebug.Print("************* ZAVPlayer::Play: " + getPlayerType(type) + " " + path)
        }
        switch type {
        case .spotify:
            spotify.manager?.setIsPlaying(true) { (NSError) in }
            spotify.playing = true
//            MMDemoAudioController.shared().pause(false)
            
        case .deezer:
            if HasTrack() {
                //                ZAudioSession.SetAppIsPlayingSound()
                deezer.player!.play()
            }
        case .napster, .appleMusic:
            service.Play()
            
        case .none:
            break
            
        default:
//            if !cPlayer.mimiInfo.inited {
//                if let mimiCreds = MimiCredentials(partnerID:"c9453e66b9b59d51b5c5548bb847fd84", andSecret:"c4411e911990654dcf2b2c5caeca7024") {
//                    Mimi.authenticate(with:mimiCreds) { (success) in
//                        cPlayer.mimiInfo.inited = true
//                    }
//                }
//            }
            if self.items().count != 0 {
                if type == .url {
                    self.playImmediately(atRate:1)
                } else {
                    self.play()
                }
                if self.status == AVPlayerStatus.failed || self.currentItem == nil || self.currentItem!.status == AVPlayerItemStatus.failed {
                    handler!.HandleAVPlayerError(self)
                    return
                }
                if getLevelMetering {
                    if let _ = currentItem?.asset.tracks {
                        /*
                        audioProcessor = [[ZNSAudioTapProcessor alloc] initWithAudioAssetTrack:tracks.firstObject]
                        audioProcessor->meterLevelHandler = Block_copy(^(double left, double right){
                        leftMeterLevel = left
                        rightMeterLevel = right
                        })
                        currentItem.audioMix = audioProcessor.audioMix
                        //                [audioProcessor setBandwidth:1]
                        //                [audioProcessor setCenterFrequency:5000]
                        */
                    }
                }
            }
        }
    }
    
    func Pause() {
        if type != .file {
            checkTimer.Stop()
        }
        //    ZDebug.Print("************* ZAVPlayer::Pause: " + getPlayerType(type))
        switch type {
            
        case .spotify:
            if spotify.manager != nil { //&& spotify.manager!.playbackState.isPlaying { // maybe not necessay?
                spotify.manager!.setIsPlaying(false) { (NSError) in  }
            }
            spotify.playing = false
            //! MMDemoAudioController.shared().pause(true)
            
        case .deezer:
            if deezer.player!.isPlaying() { // maybe not necessay?
                deezer.player!.pause()
            }
            
        case .napster, .appleMusic:
            service.Pause()
            
        case .none:
            break
            
        default:
            if self.items().count != 0 {
                self.pause()
            }
        }
    }
    
    func Stop()
    {
        ZDebug.Print("*********** ZAVPLayer.Stop:", getPlayerType(type))
        if type != .file {
            checkTimer.Stop()
        }
        switch type {
            
            case .spotify:
                //                let t = ZTime.Now
                self.spotify.manager?.setIsPlaying(false) { (NSError) in
//                    if cPlayer.mimiInfo.useSpotify {
//                        MMDemoAudioController.shared().stop()
//                    }
                }
                spotify.playing = false
            
            case .deezer:
                if deezer.player!.currentTrack != nil {
                    deezer.stopping = true
                }
                deezer.player!.stop()
                deezer.player!.next() // to really remove the current track...testing this
                
            case .napster, .appleMusic:
                service.Stop()
           
            case .none:
                break
            
            default:
                self.removeAllItems()
//                if self == cPlayer.multiPlayer.streamPlayer {
//                    installMimiTap(false)
//                }
        }
        if type != .file {
            type = .none
        }
        trackUrl = ZUrl()
    }
    
    func HasTrack() -> Bool {
        switch type {
            case .spotify:
                return spotify.manager != nil && spotify.manager!.metadata != nil // currentTrackMetadata
                
            case .deezer:
                if deezer.player == nil {
                    return false
                }
                //            ZDebug.Print(format:"--------- ZAVPlayer::HasTrack (Deezer): %d", deezer.player.currentTrack != nil)
                return deezer.player!.currentTrack != nil || deezer.gettingTrack
                
            case .napster, .appleMusic:
                return service.HasTrack()
            
            default:
                return self.items().count > 0
        }
    }
    
    func SeekToSecs(_ seconds:Double) {
        switch type {
            
        case .spotify:
            spotify.manager?.seek(to:seconds) { (error) in
                if error == nil {
                    self.spotify.position = seconds
                }
            }
            
        case .deezer:
            deezer.player!.progress = seconds
            
        case .napster, .appleMusic:
            service.SeekToSeconds(seconds)
            
        default:
            self.seek(to: CMTimeMakeWithSeconds(seconds, 1000))
        }
    }
    
    func observeMetaData()
    {
        //    metaObserving = true
        //    [self.currentItem addObserver:self forKeyPath:"timedMetadata" options:0 context:&self->itemMetadataContext]
    }
    
    func removeMetaObserver()
    {
        if metaObserving {
            //        [self.currentItem removeObserver:self forKeyPath:"timedMetadata" context:&self->itemMetadataContext]
            //        metaObserving = false
        }
    }
    
    func InsertFile(_ file:ZFileUrl) -> Bool {
        //    ZDebug.Print("************* ZAVPlayer::InsertFile: " + file.GetName())
        type = .file
        trackUrl = file
        let item = AVPlayerItem(url:file.url! as URL)
        
        if self.canInsert(item, after:nil) {
            self.removeAllItems()
            removeMetaObserver()
            self.insert(item, after:self.currentItem)
            observeMetaData()
            //        Play()
            return true
        }
        else {
            ZDebug.Print("ZAVPlayer:Error inserting file item:", item, "status:", status)
        }
        return false
    }
    
    @discardableResult func InsertStreamingUrl(_ url:ZUrl, type:PlayerType, fadeInSeconds:Double, startSeconds:Double, seekToSeconds:Double) -> Bool {
        var path = ""
        var sid = ""
        
        trackUrl = url
        path = url.ResourcePath
        if path.isEmpty {
            path = url.AbsString
        }
        ZDebug.Print("************* ZAVPlayer::InsertStreamingUrl: " + url.AbsString)
        self.type = type
        subPlayer = nil

        switch type {
            case .spotify:
                spotify.position = 0
                service = cApp.spotify
//                if cPlayer.mimiInfo.useSpotify {
                    //                    MMDemoAudioController.shared().start()
                    //                    ZAudioSession.SetAppIsPlayingSound()
                //                }
                spotify.manager?.playSpotifyURI(url.AbsString, startingWith:0, startingWithPosition:TimeInterval(0)) { (error) in
                    if error != nil {
                        ZDebug.Print("Error playing spotify url:", url.url!)
                        self.handler!.HandleAVPlayerError(self)
                    } else if seekToSeconds != 0 {
                        self.SeekToSecs(seekToSeconds)
                    }
                }
                
                return true
                
            case .deezer:
                service = cApp.deezer
                if !ZStrUtil.HasPrefix(url.AbsString, prefix:"deezer:", rest: &sid) {
                    return false
                }
                if deezer.trackRequest != nil {
                    deezer.trackRequest!.cancel()
                    deezer.player!.stop()
                }
                deezer.gettingTrack = true
                deezer.trackRequest = DZRTrack.object(withIdentifier: sid, requestManager:deezer.requestManager) { (track, error) in
                    if error != nil {
                        self.deezer.gettingTrack = false
                        ZDebug.Print("Deezer play error:", track.debugDescription, ":", String(describing: error))
                        self.handler!.HandleAVPlayerError(self)
                    } else {
                        if let t = track as? DZRTrack {
                            self.deezer.player?.play(t)
                        }
                        self.deezer.gettingTrack = false
                        if seekToSeconds != 0 {
                            self.SeekToSecs(seekToSeconds)
                        }
                        //!                        self.deezer.player!.play()
                    }
                    self.deezer.trackRequest = nil
                }
                return true
                
            case .napster:
                service = cApp.napster
                service.InsertTrack(url, seekTo:seekToSeconds)
                return true
            
            case .appleMusic:
                service = cApp.applemusic
                service.InsertTrack(url, seekTo:seekToSeconds)
                subPlayer = cApp.applemusic.player
                return true
            
            default:
                let asset = AVURLAsset(url: url.url! as URL, options:[AVURLAssetPreferPreciseDurationAndTimingKey:false])

                //let asset = AVAsset(url:url.url! as URL)
                let item = AVPlayerItem(asset:asset) // automaticallyLoadedAssetKeys:["duration"]
                //                let item = AVPlayerItem(url:url.url! as URL)
                //                 let u = "http://media.acast.com/altdusiererfeil/episode74-arnescheie/media.mp3"
                //                 let item = AVPlayerItem(url:URL(string:u)!)
                streamSeekToSeconds = seekToSeconds
                if !self.canInsert(item, after:nil) { // item == nil ||
                    handler!.HandleAVPlayerError(self)
                } else {
                    self.insert(item, after:nil)
                    let s = item.status
                    if s == AVPlayerItemStatus.failed {
                        ZDebug.Print("Insert Stream Failed: \(String(describing: self.error))")
                        //                return false
                    }
                    if seekToSeconds != 0 {
                        self.volume = 0
                    }
                    observeMetaData()
                    if type == .iPodlib {
                        Play()
                    }
                    return true
                }
                return false
        }
    }
    
    func PlayPosition() -> Double {
        switch type {
        case .spotify:
            if spotify.manager == nil {
                return 0
            }
            return spotify.position
            
        case .deezer:
            return deezer.player!.progress
            
        case .napster, .appleMusic:
            return service.PlayPosition()
            
        default:
            if self.currentItem != nil {
                return checkNAN(CMTimeGetSeconds(self.currentItem!.currentTime()))
            }
            return 0.0
        }
    }
    
    
    func PlayDuration() -> Double {
        switch type {
        case .spotify:
            if let d = spotify.manager?.metadata?.currentTrack?.duration {
                return d
            }
            return 0
            
        case .deezer:
            let length = deezer.player!.currentTrackDuration
            return Double(length)
            
        case .napster, .appleMusic:
            return service.PlayDuration()
            
        default:
            if currentItem == nil {
                return -1
            }
            if self.currentItem!.status != .readyToPlay { // it can wait a lot for duration before ready if we don't do this
                return -1
            }
            return checkNAN(CMTimeGetSeconds(self.currentItem!.asset.duration))
        }
    }
    
    func SetVolume(_ volume:Double) {
        switch type {
        case .spotify:
            spotify.manager?.setVolume(cbrt(volume)) { (error) in
                if error != nil {
                    ZDebug.Print("spotify: setVolume error", error!)
                }
            } 

            // cbrt=cubic-root. Cause spotify uses v*v*v (logarithmic). 0.2 is super-low otherwise
            //            spotify.manager?.setVolume(cbrt(volume)) { (NSError) in } // cbrt=cubic-root. Cause spotify uses v*v*v (logarithmic). 0.2 is super-low otherwise
            
        case .deezer:
            //        [deezer.player.setVolume] // not friggen made!
            break
            
        case .napster, .appleMusic:
            service.SetVolume(volume)
            
        default:
            self.volume = Float(volume)
        }
    }
    
    func ReadyTrack(zurl:ZUrl) {
        service.ReadyTrack(zurl)
    }
    
    func GetVolume() -> Float {
        switch type {
        case .spotify:
            if let v = spotify.manager?.volume {
                return Float(v*v*v)
            } else {
                return 0
            }
            
        case .deezer:
            return 0.0
            
        case .napster, .appleMusic:
            return service.GetVolume()
            
        default:
            return self.volume
        }
    }
    
    func SetBorderEvent(_ secs:Double, handler:@escaping ()->Void) {
        assert(type == .file) // just for file for now, not sure currentItem is anything yet otherwise, and won't work for spotify
        
        if self.timeObserver != nil {
            self.removeTimeObserver(self.timeObserver!)
        }
        let times = [NSValue(time:CMTimeMakeWithSeconds(secs, 1000))]
        self.timeObserver = self.addBoundaryTimeObserver(forTimes: times, queue:nil) { () in
            self.removeTimeObserver(self.timeObserver!)
            self.timeObserver = nil
            ZMainQue.async  {
                handler()
            }
        } as AnyObject?
    }
    
    func RemoveBorderEvent()
    {
        //    ZDebug.Print("ZAVPlayer::RemoveBorderEvent")
        if self.timeObserver != nil {
            self.removeTimeObserver(self.timeObserver!)
            self.timeObserver = nil
        }
    }
    
    func SetRange(_ range:ZSoundRange, done:(()->Void)? = nil) {
        SeekToSecs(range.start)
        if range.end != 0 {
            SetBorderEvent(range.end) { () in
                if done != nil {
                    done!()
                } else {
                    self.Pause()
                }
            }
        }
    }
    
    func FadeToVolume(_ volume:Double, durationSecs:Double) {
        fadeStart.time = ZTime.Now
        fadeEnd.time = fadeStart.time + durationSecs
        fadeStart.volume = Double(GetVolume())
        fadeEnd.volume = volume
        fadeTimer.Set(0.05, owner:self) { () in
            let c = ZTime.Now
            if c > self.fadeEnd.time {
                self.SetVolume(self.fadeEnd.volume);
                return false
            }
            let diff = (c - self.fadeStart.time)
            let ratio = diff / Double(self.fadeEnd.time - self.fadeStart.time)
            let fvolume = self.fadeStart.volume + ratio * (self.fadeEnd.volume - self.fadeStart.volume);
            self.SetVolume(fvolume);
            return true
        }
    }
    
    func ClearMeter()
    {
        leftMeterLevel = 0.0
        rightMeterLevel = 0.0
    }
    
    func SlowDownToZero(_ done:(()->Void)?) {
        switch type {
        case .spotify:
            Stop()
            
        case .deezer:
            Stop()
            
        default:
            if rate > 0 {
                rate *= 0.95
                if rate < 0.1 {
                    rate = 0
                }
                self.PerformAfterDelay(0.1) { () in
                    self.SlowDownToZero(done)
                }
            } else {
                if done != nil {
                    done!()
                }
            }
        }
        /*
        func GetMetaDataForCurrentItem(inout metaItems:[ZAVMetaData]) -> Bool {
            if self.currentItem != nil && self.currentItem.timedMetadata != nil {
                for m in self.currentItem.timedMetadata {
                    var meta = ZAVMetaData()
                    
                    meta.item = m
                    metaItems.append(meta)
                }
                return true
            }
            return false
        }
        */
        
        func SetEventHandler(_ handler:ZAVPlayerDelegate) {
            self.handler = handler
        }
    }
    
    fileprivate func getPlayerType(_ type:ZAVPlayer.PlayerType) -> String {
        return "\(type)".lowercased()
    }
    
    fileprivate func checkNAN(_ d:Double) -> Double {
        if d.isNaN {
            return -1
        }
        return d
    }    
    
    fileprivate func addObs(_ target:AnyObject, selector: Selector, notification:String) {
        NotificationCenter.default.addObserver(target, selector:selector, name:NSNotification.Name(rawValue: notification), object:nil)
    }
    
    fileprivate func removeObserverFromQue(_ name:String) {
        NotificationCenter.default.removeObserver(queOrg!, name:NSNotification.Name(rawValue: name), object:nil)
    }
/*
    func AddTimer(timerBase:ZTimerBase) {
        timers.append(timerBase)
    }
 */
}

// ************************************** QueueOrganizer ************************************

var queOrg: QueueOrganizer? = nil

class QueueOrganizer : NSObject {
    var players: [ZAVPlayer] = [ZAVPlayer]()
    
    override init() {
        super.init()
    }
    
    func getPlayerFromItem(_ notification:Notification) -> ZAVPlayer? {
        if let item = notification.object as? AVPlayerItem {
            for p in players {
                if p.items().contains(item) {
                    return p
                }
            }
        }
        return nil
    }
    
    // Regular AVPlayer notifications
    @objc func itemFinishedPlaying(_ notification:Notification) {
        if let player = self.getPlayerFromItem(notification) {
            player.handler!.HandleAVPlayerFinishedPlaying(player)
        }
    }
    
    @objc func itemFailedToPlayToEndTime(_ notification:Notification) {
        let error = (notification as NSNotification).userInfo![AVPlayerItemFailedToPlayToEndTimeErrorKey]
        if error != nil {
            ZDebug.Print("ZAVPlayer::itemFailedToPlayToEndTime:", error)
        }
        if let player = self.getPlayerFromItem(notification) {
            player.handler!.HandleAVPlayerFailedToPlayToEndTime(player)
        }
    }
    
    @objc func itemPlaybackStalled(_ notification:Notification) {
        if let player = self.getPlayerFromItem(notification) {
            player.handler!.HandleAVPlayerPlaybackStalled(player)
        }
    }
    
    @objc func itemNewAccessLogEntry(_ notification:Notification) {
        if let player = self.getPlayerFromItem(notification) {
            player.handler!.HandleAVPlayerStateUpdated(player)
            player.handler!.HandleAVPlayerNewAccessLogEntry(player)
        }
    }
    
    @objc func itemNewErrorLogEntry(_ notification:Notification) {
        if let player = self.getPlayerFromItem(notification) {
            player.handler!.HandleAVPlayerNewErrorLogEntry(player)
        }
    }
}


