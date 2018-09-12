//
//  ZB2.swift
//  capsulefm
//
//  Created by Tor Langballe on /14/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

// https://kothar.net/go-backblaze (go)
// https://www.backblaze.com/b2/docs/

import Foundation

// account id: cc156c3d59c2
// app id: 001e5c095bde96558afb95736e822025a35895d1ba

class ZBackblazeB2 {
    var apiUrl = ""
    var accountId = ""
    var appId = ""
    var authorizationToken = ""
    init(accountId:String, appId:String) {
        self.accountId = accountId
        self.appId = appId
    }
    
    func Setup(_ done:@escaping (_ error:Error?)->Void) {
        if apiUrl.isEmpty {
            AuthorizeAccount(done)
        } else {
            done(nil)
        }
    }

    func AuthorizeAccount(_ done:@escaping (_ error:Error?)->Void) {
        let req = ZUrlRequest.Make(.Get, url:"https://api.backblazeb2.com/b2api/v1/b2_authorize_account")
        var str = accountId + ":" + appId
        str = "Basic" + ZStr.Base64Encode(str)
        req.SetHeaderForKey("Authorization", value:str)
        
        ZUrlSession.SendGetJson(req, debug:true) { (response, json, error) in
            if error == nil {
                self.apiUrl = json["apiUrl"].stringValue + "/b2api/v1/"
                self.authorizationToken = json["authorizationToken"].stringValue
            }
            done(error)
        }
    }

    func GetUploadUrlForBucketId(_ bucketId:String, done:@escaping (_ error:Error?, _ uploadUrl:String, _ uploadToken:String)->Void) {
        let req = ZUrlRequest.Make(.Post, url:apiUrl + "b2_get_upload_url")
        req.SetHeaderForKey("Authorization", value:authorizationToken)
        var json = ZJSON.JDict()
        json["bucketId"] = ZJSON(bucketId)
        req.SetJsonBody(json)
        ZUrlSession.SendGetJson(req, debug:true) { (response, json, error) in
            if error == nil {
                let uploadUrl = json["uploadUrl"].stringValue
                let uploadToken = json["authorizationToken"].stringValue
                done(nil, uploadUrl, uploadToken)
            } else {
                done(error, "", "")
            }
        }
    }

    func UploadFileToUrlWithToken(_ fileData:ZData, name:String, mimeType:String = "b2/x-auto", uploadUrl:String, uploadToken:String, done:@escaping (_ error:Error?, _ fileId:String)->Void) {
        let req = ZUrlRequest.Make(.Post, url:uploadUrl)
        let sha1 = ZCrypto.Sha1AsHex(fileData)
        req.SetHeaderForKey("Authorization", value:uploadToken)
        req.SetHeaderForKey("X-Bz-File-Name", value:ZStr.UrlEncode(name) ?? "")
        req.SetHeaderForKey("Content-Type", value:mimeType)
        req.SetHeaderForKey("Content-Length", value:"\(fileData.count)")
        req.SetHeaderForKey("X-Bz-Content-Sha1", value:sha1)
        
        req.httpBody = fileData
        ZUrlSession.SendGetJson(req, debug:true) { (response, json, error) in
            if error == nil {
                //                let uploadUrl = json["uploadUrl"].stringValue
                done(nil, "")
            } else {
                done(error, "")
            }
        }
    }

    func UploadFileToBucket(_ fileData:ZData, buckedId:String, bucketName:String, name:String, mimeType:String = "b2/x-auto", uploader:ZImageUploader) {
        UploadFileToBucket(fileData, buckedId:buckedId, bucketName:bucketName, name:name) { (url, strId, error) in
            uploader.error = error
            uploader.strId = strId
            uploader.url = url
            uploader.done?(uploader)
        }
    }

    func UploadFileToBucket(_ fileData:ZData, buckedId:String, bucketName:String, name:String, mimeType:String = "b2/x-auto", done:@escaping (_ url:String, _ strId:String, _ error:Error?)->Void) {
        Setup { (error) in
            if error != nil {
                done("", "", error)
            } else {
                self.GetUploadUrlForBucketId(buckedId) { (error, uploadUrl, uploadToken) in
                    if error == nil {
                        self.UploadFileToUrlWithToken(fileData, name:name, mimeType:mimeType, uploadUrl:uploadUrl, uploadToken:uploadToken) { (error, fileId) in
                            if error == nil {
                                let url = "https://f001.backblazeb2.com/file/" + (ZStr.UrlEncode(bucketName) ?? "") + "/" + (ZStr.UrlEncode(name) ?? "")
                                done(url, fileId, error )
                            } else {
                                done("", "", error)
                            }
                        }
                    } else {
                        done("", "", error)
                    }
                }
            }
        }
    }
}

