//
//  ZLinkLabel.swift
//  PocketProbe
//
//  Created by Tor Langballe on /22/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import UIKit
class ZLinkLabel : ZLabel {
    func SetUrl(_ url:String) {
        HandlePressedInPosFunc = { (pos) in
            mainZApp?.HandleOpenUrl(ZUrl(string:url))
        }
    }
}
