//
//  ZPasteboard.swift
//
//  Created by Tor Langballe on /30/4/16.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

class ZPasteboard {
    static var PasteString : String {
        get {
            #if os(iOS)
            return UIPasteboard.general.string ?? ""
            #else
            return ""
            #endif
        }
        set {
            #if os(iOS)
            UIPasteboard.general.string = newValue
            #endif
        }
    }
}
