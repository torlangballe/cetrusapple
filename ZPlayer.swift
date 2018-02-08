//
//  ZPlayer.swift // will be ZAVPlayer one day
//  Cetrus
//
//  Created by Tor Langballe on /29/1/18.
//

import AVFoundation

typealias ZPlayer = AVPlayer
extension ZPlayer {
    @discardableResult func AddIntervalObserver(secs:Double, onMain:Bool = true, got:@escaping (_ t:Double)->Void) -> Any {
        let que:DispatchQueue? = onMain ? ZMainQue : nil
        return addPeriodicTimeObserver(forInterval:CMTimeMakeWithSeconds(secs, 1000), queue:que) { (cmtime) in
            got(CMTimeGetSeconds(cmtime))
        }
    }
    
    func RemoveTimeObserver(observer:Any) {
        removeTimeObserver(observer)
    }
}

