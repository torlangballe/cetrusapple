//
//  ZError.swift
//  Zed
//
//  Created by Tor Langballe on /5/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

//typealias Error = Error

var ZGeneralError = ZError(message:"Zed", code:1)

let ZUrlErrorDomain = NSURLErrorDomain
let ZCapsuleErrorDomain = "fm.capsule.error"

class ZError : NSError {
    convenience init(message:String, code:Int = 0) {
        self.init(domain:"Zed", code:code, userInfo:[NSLocalizedDescriptionKey:message])
    }
}

extension Error {
    
    func GetMessage() -> String {
        let ns = self as NSError
        if let m = ns.userInfo["message"] as? String {
            return m
        }
        return localizedDescription
    }

    func GetTypeString() -> String {
        let ns = self as NSError
        if let m = ns.userInfo["__type"] as? String {
            return m
        }
        return ""
    }
}

