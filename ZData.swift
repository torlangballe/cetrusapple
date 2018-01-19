//
//  ZData.swift
//  Zed
//
//  Created by Tor Langballe on /31/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZData = Data

extension ZData {
    init?(fileUrl:ZFileUrl) {
        do {
            try self.init(contentsOf:fileUrl.url!)
        } catch let error {
            ZDebug.Print("ZData.init from fileUrl err:", error.localizedDescription)
            return nil
        }
    }
    
    static func FromUrl(_ url:ZUrl) -> ZData? {
        do {
            return try Data(contentsOf:url.url!)
        } catch let error as NSError {
            ZDebug.Print("ZData.FromUrl error:", error.localizedDescription)
            return nil
        }
    }
    
    func GetString() -> String {
        if let s = NSString(data:self, encoding:String.Encoding.utf8.rawValue) {
            return s as String
        }
        return ""
    }
    
    func GetHexString() -> String {
        let buffer = self.withUnsafeBytes {
            Array(UnsafeBufferPointer<UInt8>(start: $0, count: self.count/MemoryLayout<UInt8>.size))
        }
        
        var hex = ""
        for i in 0..<self.count {
            hex += String(format: "%02x", buffer[i])
        }
        return hex
    }
    
    @discardableResult func SaveToFile(_ file:ZFileUrl) -> Error? {
        do {
            try write(to: file.url! as URL, options:.atomic)
        } catch let error {
            return error
        }
        return nil
    }
    
    @discardableResult func LoadFromFile(_ file:ZFileUrl) -> Error? {
        do {
            try write(to: file.url! as URL, options:.atomic)
        } catch let error {
            return error
        }
        return nil
    }
    
    init?(utfString:String) {
        if let d = utfString.data(using: String.Encoding.utf8) {
            self.init(referencing:d as NSData)
        } else {
            return nil
        }
    }

    init?(hexString:String) {
        var d = ZData()
        var word = ""
        for c in hexString {
            word.append(c)
            if word.count == 2 {
                var ch: UInt32 = 0
                Scanner(string:word).scanHexInt32(&ch)
                var char = UInt8(ch)
                d.append(&char, count: 1)
                word = ""
            }
        }
        self.init(referencing:d as NSData)
    }
}
