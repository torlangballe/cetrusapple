//
//  ZMediaPlayer
//  Zetrus
//
//  Created by Tor Langballe on /29/1/18.
//

import AVFoundation

typealias ZMediaPlayer = AVPlayer
extension ZMediaPlayer {
@discardableResult func AddIntervalObserver(secs:Double, onMain:Bool = true, got:@escaping (_ t:Double)->Void) -> Any {
        let que:DispatchQueue? = onMain ? ZMainQue : nil
    return addPeriodicTimeObserver(forInterval:CMTimeMakeWithSeconds(secs, preferredTimescale: 1000), queue:que) { (cmtime) in
            got(CMTimeGetSeconds(cmtime))
        }
    }
    
    func RemoveTimeObserver(observer:Any) {
        removeTimeObserver(observer)
    }
}

