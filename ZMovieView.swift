//
//  ZMoviePlayer.swift
//  PocketProbe
//
//  Created by Tor Langballe on /18/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import AVKit

class ZMovieView : ZCustomView {
    var player:ZPlayer? = nil
    var seeking = false
    var handlePlayPause: ((_ play:Bool)->Void)? = nil
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
            player = AVPlayer(playerItem:playerItem)
            playerLayer = AVPlayerLayer(player:player!)
            playerLayer!.videoGravity = .resizeAspect
            self.layer.addSublayer(playerLayer!)
            playerLayer!.frame = self.bounds
            player?.play()
            player?.addObserver(self, forKeyPath:"rate", options:NSKeyValueObservingOptions(), context:nil)
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
            player?.seek(to: CMTimeMakeWithSeconds(newValue, 1000)) { [weak self] (finished) in
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            handlePlayPause?(player!.rate != 0)
        }
    }
}
