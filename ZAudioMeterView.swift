//
//  ZAudioMeterView.swift
//  capsulefm
//
//  Created by Tor Langballe on /4/12/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZAudioMeterView: ZCustomView {
    var samples = [Float32]()
    let timer = ZRepeater()
    var mutex = ZMutex()
    
    override init(name:String = "audiometerview") {
        super.init(name:name)
        minSize = ZSize(50, 50)
        //SetBackgroundColor(ZColor.Red())
        timer.Set(0.05, owner:self) { [weak self] () in
            self?.Expose()
            return true
        }
        foregroundColor = ZColor(r:1, g:1, b:1, a:0.4)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func AddSample(_ sample:Float32) {
        mutex.Lock()
        samples.append(sample)
        
        if samples.count > Int(Rect.size.w / 10) {
            samples.remove(at:0)
        }
        mutex.Unlock()
    }
    
    func Clear() {
        mutex.Lock()
        samples.removeAll()
        mutex.Unlock()
        Expose()
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        let c = rect.size.h / 2
        let h2 = c
        let path = ZPath()
        let w = rect.size.w / Double(samples.count) / 2
        
        var max = 0.0
        for s in samples {
            maximize(&max, Double(s))
        }
        mutex.Lock()
        path.MoveTo(ZPos(0, c))
        for i in 0 ..< samples.count {
            let d = π
            let x = Double(i) * rect.size.w / Double(samples.count)
            let s = (i < samples.count - 1) ? abs(samples[i]) : 0.0;
            var hs = Double(s) / max * h2
            minimize(&hs, c - 1)
            if hs < w {
                path.LineTo(ZPos(x + w*2, c))
            } else {
                let r1 = ZRect(x, c - hs, x + w, c - hs + w)
                path.ArcTo(r1, radstart:-π / 2, radDelta:d, clockwise:false)
                let r2 = ZRect(x + w, c + hs - w, x + w*2, c + hs)
                path.ArcTo(r2, radstart:-π / 2, radDelta:d, clockwise:true)
            }
        }
        mutex.Unlock()

        canvas.SetColor(foregroundColor)
        canvas.StrokePath(path, width:2)
    }
}

