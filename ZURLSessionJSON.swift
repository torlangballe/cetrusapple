//
//  ZURLSessionJSON.swift
//  PocketProbe
//
//  Created by Tor Langballe on /13/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import Foundation

extension ZInternet {
    static func SendGetJson(_ req:ZUrlRequest, onMain:Bool = true, async:Bool = true, sessionCount:Int = -1, debug:Bool = false, done:@escaping (_ response:ZUrlResponse?, _ json:ZJSON, _ error:Error?)->Void) {
        ZUrlSession.Send(req, onMain:onMain, async:async, sessionCount:sessionCount, makeStatusCodeError:true) { (response, data, error, sessionCount) in
            if error == nil && data != nil {
                var err:Error? = nil
                let json = ZJSON(zdata:data!, error:&err)
                done(response, json ?? ZJSON(), err)
                return
            }
            done(response, ZJSON(), error)
        }
    }
}

extension ZUrlRequest {
    func SetJsonBody(_ json:ZJSON) {
        httpBody = json.data as Data?
    }
}
