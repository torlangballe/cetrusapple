//
//  ZURLConnection.swift
//  Zed
//
//  Created by Tor Langballe on /5/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZUrlRequest = NSMutableURLRequest
typealias ZUrlResponse = URLResponse
typealias ZURLSessionTask = URLSessionTask

extension ZURLSessionTask {
    func FractionCompleted() -> Double {
        if #available(iOS 11.0, *) {
            return progress.fractionCompleted
        }
        return 0
    }
}
extension ZUrlResponse {
    var StatusCode: Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return nil
    }
    
    var ContentLength: Int {
        if let httpResponse = self as? HTTPURLResponse {
            if let scl = httpResponse.allHeaderFields["Content-Length"] as? String {
                return Int(scl) ?? -1
            }
        }
        return -1
    }
    
    func GetSimpleStringHeaders() -> [String:String] {
        var args = [String:String]()
        if let httpResponse = self as? HTTPURLResponse {
            for (k, v) in httpResponse.allHeaderFields {
                if let sk = k as? String, let sv = v as? String {
                    args[sk] = sv
                }
            }
        }
        return args
    }
}

enum ZUrlRequestType: String {
    case Post = "POST"
    case Get = "GET"
    case Put = "PUT"
    case Delete = "DELETE"
}

struct ZUrlRequestReturnMessage : Codable, ZCopy {
    var messages:[String]? = nil
    var message:String? = nil
    var code:Int? = nil
}

extension ZUrlRequest {
    func SetUrl(_ url: String) {
        self.url = URL(string:url)
    }
    
    func SetType(_ type:ZUrlRequestType) {
        httpMethod = type.rawValue
    }
    
    static func Make(_ type:ZUrlRequestType, url:String, timeOutSecs:Int = 0, args:[String:String] = [:]) -> ZUrlRequest {
        let req = ZUrlRequest()
        var vurl = url
        if args.count > 0 {
            vurl += "?" + args.stringFromHttpParameters()
        }
        req.SetUrl(vurl)
        if timeOutSecs != 0 {
            req.timeoutInterval = TimeInterval(timeOutSecs)
        }
        req.SetType(type)
        return req
    }

    func SetHeaderForKey(_ key:String, value:String) {
        setValue(value, forHTTPHeaderField:key)
    }    
}

private func checkStatusCode(_ response:ZUrlResponse!, check:Bool, error:inout ZError?) {
    if check {
        if error == nil {
            if let code = response.StatusCode {
                if code >= 300 {
                    let str = HTTPURLResponse.localizedString(forStatusCode: code)
                    error = ZNewError(str, code:code, domain:ZUrlErrorDomain)
                }
            }
        }
    }
}

class ZUrlSession {
    // transactions are debugging list for listing all transactions
    static var transactionMutex = ZMutex()
    static var transactions = [(String, Int, Bool)]() // url, length, upload
    
    @discardableResult static func Send(_ request:ZUrlRequest, onMain:Bool = true, async:Bool = true, sessionCount:Int = -1, makeStatusCodeError:Bool = false, done:@escaping (_ response:ZUrlResponse?, _ data:ZData?, _ error:ZError?, _ sessionCount:Int)->Void) -> ZURLSessionTask? {
        if !async {
            SendSync(request, sessionCount:sessionCount, makeStatusCodeError:makeStatusCodeError, done:done)
            return nil
        }
        if request.httpBody != nil {
            if request.url != nil && request.httpBody != nil {
                transactionMutex.Lock()
                transactions.append((request.url!.absoluteString, request.httpBody!.count, true))
                transactionMutex.Unlock()
            }
        }
        let task = URLSession.shared.dataTask(with:(request as URLRequest)) { (data, response, error) in
//            ZDebug.Print("ZUrlSession.Sent", data?.count, error?.localizedDescription, request.url?.absoluteString)
            if error != nil {
                ZDebug.Print("ZUrlSession.Send dataTask err:", error!.localizedDescription, request.url?.absoluteString)
            }
            var verror = error
            checkStatusCode(response, check:makeStatusCodeError, error:&verror)
            if data != nil {
                transactionMutex.Lock()
                transactions.append((request.url!.absoluteString, data!.count, false))
                transactionMutex.Unlock()
            }
            if onMain {
                ZMainQue.async {
                    done(response, data, verror, sessionCount)
                }
            } else {
                done(response, data, verror, sessionCount)
            }
        }
        task.resume()
        
        return task
    }
    
    static func DownloadPersistantlyToFileInThread(_ request:ZUrlRequest, onCellular:Bool? = nil, makeStatusCodeError:Bool = false, done:@escaping (_ response:ZUrlResponse?, _ file:ZFileUrl?, _ error:ZError?)->Void) -> ZURLSessionTask? {
        let config = URLSessionConfiguration.default
        config.isDiscretionary = true
        let session = URLSession(configuration:config)

//        let session = URLSession.shared
//        if onCellular != nil {
//            session.configuration.allowsCellularAccess = onCellular!
//        }
        let task = session.downloadTask(with:(request as URLRequest)) { (furl, response, error) in
            var verror = error
            checkStatusCode(response, check:makeStatusCodeError, error:&verror)
            if furl != nil {
                done(response, ZFileUrl(nsUrl:furl!), verror)
            } else {
                done(response, nil, verror)
            }
        }
        task.resume()
        return task
    }
    
    static func SendSync(_ request:ZUrlRequest, timeoutSecs:Double = 11, sessionCount:Int = -1, makeStatusCodeError:Bool = false, done:@escaping (_ response:ZUrlResponse?, _ data:ZData?, _ error:ZError?, _ sessionCount:Int)->Void) {
        print("SendSync:", request.url!)
        let downloadGroup = DispatchGroup()
        downloadGroup.enter()
        var vresponse:ZUrlResponse? = nil
        var vdata:ZData? = nil
        var verror:ZError? = nil
        var vscount = sessionCount
        Send(request, onMain:false, sessionCount:sessionCount, makeStatusCodeError:makeStatusCodeError) { (resp, data, err, scount) in
            downloadGroup.leave()
            vresponse = resp
            vdata = data
            verror = err
            vscount = scount
        }
        if downloadGroup.wait(timeout: ZDispatchTimeInSecs(timeoutSecs)) == .timedOut {
            verror = ZNewError("SendSync, timed out: " + (request.url?.absoluteString)!)
        }
        done(vresponse, vdata as ZData?, verror, vscount)
    }
    
    static func GetAllCookies() -> [String] {
        var cookies = [String]()
        if let store = HTTPCookieStorage.shared.cookies {
            for c in store {
                cookies.append(c.name)
            }
        }
        return cookies
    }
    
    static func DeleteAllCookiesForDomain(_ domain: String) {
        var vdomain = domain
        let hasSuffix = ZStr.HasPrefix(vdomain, prefix:"*", rest:&vdomain);
        if let store = HTTPCookieStorage.shared.cookies {
            for c in store {
                if (hasSuffix && String(c.domain).hasSuffix(vdomain)) || (!hasSuffix && String(c.domain) == vdomain) {
                    HTTPCookieStorage.shared.deleteCookie(c)
                }
            }
        }
        UserDefaults.standard.synchronize()
    }
    
    static func CheckError(data:ZJSONData) -> (ZError?, Int?) {
        var m = ZUrlRequestReturnMessage()
        if data.Decode(&m) == nil {
            if m.messages != nil && m.messages!.count != 0 {
                return (ZNewError(m.messages!.first!), nil)
            }
            if m.message != nil {
                return (ZNewError(m.message!), m.code)
            }
        }
        return (nil, nil)
    }    
}

