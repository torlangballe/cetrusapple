//
//  ZControl.swift
//  Zed
//
//  Created by Tor Langballe on /24/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

typealias ZControlEvents = UIControlEvents

public enum ZControlEventType: Int {
    case pressed = 1
    case valueChanged = 2
}

public protocol ZControl {
    var High: Bool { get set }
    func Control() -> UIControl
    func AddTarget(_ target: AnyObject?, forEventType: ZControlEventType)
}

extension ZControl {
    public var High: Bool {
        get {
            return Control().isHighlighted
        }
        set {
            Control().isHighlighted = newValue
        }
    }
    public func AddTarget(_ target: AnyObject?, forEventType: ZControlEventType) {
        switch forEventType {
            case .pressed:
                Control().addTarget(target,
                    action:#selector(ZCustomView.handlePressed(_:)),
                    for:UIControlEvents.touchUpInside)
            
            case ZControlEventType.valueChanged:
                Control().addTarget(target,
                    action:#selector(ZCustomView.handleValueChanged(_:)),
                    for:UIControlEvents.valueChanged)
        }
    }
}

