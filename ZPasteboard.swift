//
//  ZPasteboard.swift
//
//  Created by Tor Langballe on /30/4/16.
//

// #package com.github.torlangballe.CetrusAndroid

import UIKit

class ZPasteboard {
    static var PasteString : String {
        get { return UIPasteboard.general.string ?? "" }
        set { UIPasteboard.general.string = newValue }
    }
}
