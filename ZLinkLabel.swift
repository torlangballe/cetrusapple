//
//  ZLinkLabel.swift
//
//  Created by Tor Langballe on /22/12/17.
//

// #package com.github.torlangballe.CetrusAndroid

import UIKit
class ZLinkLabel : ZLabel {
    func SetUrl(_ url:String) {
        HandlePressedInPosFunc = { (pos) in
            mainZApp?.HandleOpenUrl(ZUrl(string:url))
        }
    }
}
