//
//  ZSwitch.Apple.swift
//
//  Created by Tor Langballe on /14/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

#if os(tvOS)
    typealias ZSwitch = ZBallSwitch
#else
class ZSwitch: UISwitch, ZView, ZControl {
    var objectName: String = "ZSwitch"
    var edited = false
    func View() -> UIView { return self }
    func Control() -> UIControl { return self }
    
    init(value:Bool = false) {
        super.init(frame:CGRect(x:0, y:0, width:10, height:10))
        Value = value
        AddTarget(self, forEventType:.valueChanged)
    }

    var Value: Bool {
        get { return isOn }
        set { isOn = newValue }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleValueChanged(_ sender:UIView) {
        edited = true
    }
}
#endif

