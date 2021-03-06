//
//  ZUrl.swift
//
//  Created by Tor Langballe on /30/10/15.
//

import Foundation

#if os(iOS)
import SafariServices
import MobileCoreServices
#endif

class ZUrl : Hashable  {
    var url: URL?

    var hashValue: Int {
        return url?.hashValue ?? 0
    }
    
    init() {
        url = nil
    }

    init(string:String) {
        if let u = URL(string:string) {
            url = u
        } else {
            url = nil
        }
    }

    init(nsUrl:URL) {
        url = nsUrl
    }

    init(url:ZUrl) {
        self.url = url.url
    }

    var IsEmpty : Bool {
        return url == nil
    }

    func IsDirectory() -> Bool {
        if url == nil {
            return false
        }
        var o: AnyObject?
        do {
            try (url! as NSURL).getResourceValue(&o, forKey:URLResourceKey.isDirectoryKey)
        } catch {
            // handle error
        }
        if let n = o as? NSNumber {
            return n.intValue == 1
        }
        return false
    }

    func OpenInBrowser(inApp:Bool, notInAppForSocial:Bool = true) {
        var out = false
        if inApp {
            if let host = url?.host {
                if host.hasSuffix("twitter.com") || host.hasSuffix("facebook.com") {
                    out = true
                }
            }
        }
        #if os(iOS)
        if inApp && !out {
            let c = SFSafariViewController(url:url!)
            ZGetTopViewController()!.present(c, animated:true, completion:nil)
            return
        }
        UIApplication.shared.open(url!, options:[:]) // can have completion handler too
        #endif
    }

    func GetName() -> String {
        if url != nil {
            return url!.lastPathComponent // if lastPathComponent is nil, ?? returns ""
        }
        return ""
    }
    
    var Scheme : String{
        get { return url?.scheme ?? "" }
    }
    
    var Host : String {
        get { return url?.host ?? "" }
    }
    
    var Port : Int {
        get { return url?.port ?? -1 }
    }
    
    var AbsString : String {
        get { return url?.absoluteString ?? "" }
    }
        
    var ResourcePath : String {
        get { return url?.path ?? "" }
    }

    var Extension : String {
        get { return url?.pathExtension ?? "" }
        set {
            if url != nil {
                url = url!.appendingPathExtension(newValue)
            }
        }
    }
    
    var Anchor : String { // called fragment really
        return url?.fragment ?? ""
    }
    
    var Parameters: [String:String] {
        get {
            if let q = url?.query {
                return ZUrl.ParametersFromString(q)
            }
            let tail = ZStr.TailUntil((url?.absoluteString) ?? "", sep:"?")
            if !tail.isEmpty {
                return ZUrl.ParametersFromString(tail)
            }
            return [String:String]()
        }
    }
    
    static func ParametersFromString(_ parameters:String) -> [String:String] {
        var queryStrings = [String: String]()
        for qs in parameters.components(separatedBy: "&") {
            let comps = qs.components(separatedBy: "=")
            if comps.count == 2 {
            let key = comps[0]
                var value = comps[1]
                value = value.replacingOccurrences(of: "+", with: " ")
                value = value.removingPercentEncoding ?? ""
                queryStrings[key] = value
            }
        }
        return queryStrings
    }
}

func ==(lhs: ZUrl, rhs: ZUrl) -> Bool {
    return lhs.url == rhs.url
}

