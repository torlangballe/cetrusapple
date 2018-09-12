//
//  ZOAuth.swift
//  capsulefm
//
//  Created by Tor Langballe on /12/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

// OAuth Beginners Guide: http://hueniverse.com/oauth/
// Google signing Script: http://oauth.googlecode.com/svn/code/javascript/example/signature.html

class ZOAuth {
    var sconsumerKey = "", sconsumerSecret = ""
    var sauthToken = "", sauthTokenSecret = ""
    var sauthVerifier = ""
    
    func GetAuthorizationHeader(_ url:String, callbackUrl:String, get:Bool, urlArgs:[String:String]) -> String {
        let shttpmethod = get ? "GET" : "POST"
        let stimestamp = "\(ZTime.Now().date.timeIntervalSince1970)"
        let snonce = ZCrypto.MakeUuid()
        
        //url = "https://api.twitter.com/1/statuses/update.json"
        //sconsumerKey = "xvz1evFS4wEEPTGEFPHBog"
        //stimestamp = "1318622958"
        //    sconsumerSecret = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
        //    snonce = "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg"
        //    sauthToken = "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb"
        //    sauthTokenSecret = "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"
        
        //stimestamp = "1416189824"
        //snonce = "a5d3a7a3182e6d4c64fb91cad3fa1ff8"
        
        var authargs = [
            "oauth_consumer_key": sconsumerKey,
            "oauth_nonce": snonce,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": stimestamp,
            "oauth_version": "1.0",
        ]
        if !callbackUrl.isEmpty {
            authargs["oauth_callback"] = callbackUrl
        }
        
        if !sauthToken.isEmpty {
            authargs["oauth_token"] = sauthToken
        }
        var args = authargs
        args += urlArgs
        
        var sargs = args.stringFromHttpParameters()
        sargs = ZStr.UrlEncode(sargs) ?? ""
        
        let ssignaturebase = shttpmethod + "&" + (ZStr.UrlEncode(url) ?? "") + "&" + sargs
        let skey  = (ZStr.UrlEncode(sconsumerSecret) ?? "") + "&" + (ZStr.UrlEncode(sauthTokenSecret) ?? "")
        
        let ssignature64 = ZCrypto.HmacSha1ToBase64(ssignaturebase, key:skey)
        authargs["oauth_signature"] = ssignature64
        
        let sauthorizationHeader = "OAuth " + authargs.stringFromHttpParameters() // stringFromHttpParameters sorts now
        
        return sauthorizationHeader
    }
}


