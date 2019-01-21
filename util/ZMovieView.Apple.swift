//
//  ZMovieView.swift
//
//  Created by Tor Langballe on /18/12/17.
//

// #package com.github.torlangballe.cetrusandroid


import AVKit

private var kAVPlayerItemKVOContext = 0

class ZMovieView : ZCustomView {
    var player:ZMediaPlayer? = nil
    var seeking = false
    var handlePlayPause: ((_ play:Bool)->Void)? = nil
    var handleError: ((_ error:ZError)->Void)? = nil
    var playerLayer:AVPlayerLayer? = nil

    init() {
        super.init(name:"zmovieview")
    }

    deinit {
        player?.removeObserver(self, forKeyPath:"rate", context:nil)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func SetUrl(_ url:String) {
        if let u = URL(string:url) {
            let playerItem = AVPlayerItem(url:u)
            // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
            player = ZMediaPlayer(playerItem:playerItem)
            playerLayer = AVPlayerLayer(player:player!)
            playerLayer!.videoGravity = .resizeAspect
            self.layer.addSublayer(playerLayer!)
            playerLayer!.frame = self.bounds
            player?.play()
            player?.addObserver(self, forKeyPath:"rate", options:NSKeyValueObservingOptions(), context:nil)
            player?.addObserver(self, forKeyPath:"status", options:NSKeyValueObservingOptions(), context:nil)
            player?.addObserver(self, forKeyPath:"currentItem.status", options:NSKeyValueObservingOptions(rawValue: 0), context:&kAVPlayerItemKVOContext)
        }
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if object is AVPlayer {
                if player!.status == AVPlayer.Status.failed && player!.error != nil {
                    handleError?(player!.error!)
                }
            }
            return
        }
        if keyPath == "rate" {
            handlePlayPause?(player!.rate != 0)
            return
        }
        if context == &kAVPlayerItemKVOContext && object is AVPlayer && keyPath == "currentItem.status" {
            if player!.currentItem!.status == AVPlayerItem.Status.failed && player!.currentItem!.error != nil {
                handleError?(player!.currentItem!.error!)
            }
            return
        }
    }

    override func HandleAfterLayout() {
        playerLayer?.frame = self.bounds
    }
    
    func Play() {
        player?.play()
    }

    func Pause() {
        player?.pause()
    }

    var Pos: Double {
        get {
            if player != nil && player!.currentItem != nil {
                return ZMath.NanCheck(CMTimeGetSeconds(player!.currentItem!.currentTime()), set:0)
            }
            return 0.0
        }
        set {
            seeking = true
            player?.seek(to: CMTimeMakeWithSeconds(newValue, preferredTimescale: 1000)) { [weak self] (finished) in
                self?.seeking = !finished
            }
        }
    }
    var Duration: Double {
        get {
            if player != nil && player!.currentItem != nil {
                return ZMath.NanCheck(CMTimeGetSeconds(player!.currentItem!.duration), set:0)
            }
            return 0.0
        }
    }
}
