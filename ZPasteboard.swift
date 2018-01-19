//
//  ZPasteboard.swift
//  capsulefm
//
//  Created by Tor Langballe on /30/4/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZPasteboard {
    static var PasteString : String {
        get { return UIPasteboard.general.string ?? "" }
        set { UIPasteboard.general.string = newValue }
    }
}
