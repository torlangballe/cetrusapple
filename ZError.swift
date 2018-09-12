//
//  ZError.swift
//  Zed
//
//  Created by Tor Langballe on /5/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZError = Error

func ZNewError(_ message:String, code:Int = 0, domain:String = "Zetrus") -> ZError {
    return NSError(domain:domain, code:code, userInfo:[NSLocalizedDescriptionKey:message])
}

extension ZError {
    func GetMessage() -> String {
        return localizedDescription
    }
}

var ZGeneralError = ZNewError("Zed", code:1)

let ZUrlErrorDomain = NSURLErrorDomain
let ZCapsuleErrorDomain = "fm.capsule.error"

