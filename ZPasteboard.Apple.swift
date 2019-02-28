//
//  ZPasteboard.swift
//
//  Created by Tor Langballe on /30/4/16.
//

// #package com.github.torlangballe.cetrusandroid

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class ZPasteboard {
    static var PasteString : String {
        get {
            #if os(macOS)
            for element in NSPasteboard.general.pasteboardItems! {
                if let str = element.string(forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")) {
                    return str
                }
            }
            return ""
            #elseif os(iOS)
            return UIPasteboard.general.string ?? ""
            #else
            return ""
            #endif
        }
        set {
            #if os(macOS)
            let pb = NSPasteboard.init(name: NSPasteboard.Name.general)
            pb.string(forType: NSPasteboard.PasteboardType.string)
            pb.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pb.setString(newValue, forType: NSPasteboard.PasteboardType.string)
            #elseif os(iOS)
            UIPasteboard.general.string = newValue
            #endif
        }
    }
}
