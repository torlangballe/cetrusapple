//
//  ZUrlCache.swift
//  Zed
//
//  Created by Tor Langballe on /2/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

class ZUrlCache {
    var folder: ZFileUrl
    var addingList = [String:ZURLSessionTask]()
    var persistent = false
    var onCellular:Bool? = nil
    var addExtensionAtEnd = true
    
    init(name:String, removeOldHours:Double = 0) {
        folder = ZFolders.GetFileInFolderType(.caches, addPath:name)
        if removeOldHours != 0 {
            RemoveOld(removeOldHours)
        }
        folder.CreateFolder()
        
        let preCachedFolder = ZFolders.GetFileInFolderType(.resources, addPath:"ZUrlCache/" + name)
        if preCachedFolder.Exists() {
            preCachedFolder.Walk() { (furl, finfo) in
                let name = furl.GetName()
                if let url = ZStrUtil.UrlDecode(name) {
                    let file = makeFile(url:url)
                    if !file.Exists() {
                        let err = furl.CopyTo(file)
                        if err != nil {
                            ZDebug.Print("ZUrlCache copy precached error:", err!, furl.url!, file.url!)
                        }
                    }
                }
                return true
            }
        }
    }

    func IsGetting(_ url:String) -> Bool {
        if addingList[url] != nil {
            return true
        }
        return false
    }
    

    func IsGettingOrGotten(_ url:String) -> Bool {
        if IsGetting(url) {
            return true
        }
        if HasUrl(url) {
            return true
        }
        return false
    }
    
    func makeFile(url:String) -> ZFileUrl {
        //        let (base, _, stub, ext) = ZFileUrl.GetPathParts(url)
        //        let str = ZFileUrl.AbsString
        //        let str = ZStrUtil.TruncateMiddle(base + stub, maxChars:100, separator:"…")
        let ext = ZUrl(string:url).Extension
        let path = ZFileUrl.GetLegalFilename(url) // leave enough for a big path in file to get to here too
        let file = folder.AppendedPath(path)
        let fext = file.Extension
        if (fext.isEmpty || fext.contains("?")) && !ext.isEmpty && addExtensionAtEnd {
            file.Extension = ext
        }
        return file
    }

    func HasUrl(_ url:String) -> Bool {
        var file = ZFileUrl()
        return HasFile(url, file:&file)
    }

    func HasFile(_ url:String, file:inout ZFileUrl) -> Bool {
        if url.isEmpty {
            return false
        }
        file = makeFile(url:url)
        if file.Exists() {
            return true
        }
        return false
    }
    
    func FractionCompleted(_ url:String) -> Float? {
        if HasUrl(url) {
            return 1
        }
        if let task = addingList[url] {
            return Float(task.FractionCompleted())
        }
        return nil
    }

    func StopDownload(url:String) {
        if let task = addingList[url] {
            task.cancel()
            addingList.removeValue(forKey:url)
        }
    }

    func RemoveUrl(_ url:String) {
        if let task = addingList[url] {
            task.cancel()
            addingList.removeValue(forKey:url)
        }
        let file = makeFile(url:url)
        file.Remove()
    }

    @discardableResult func GetUrl(_ url:String) -> ZFileUrl? { // discardable since sometimes we want to just force-cache something
        if url == "http://capsuleaudio.s3.amazonaws.com/" {
            print("bad url:", url)
        }
        var file = ZFileUrl()
        if HasFile(url, file:&file) {
            file.Modified = ZTime.Now
            return file
        }
        if addingList[url] != nil {
            return nil
        }
        let req = ZUrlRequest()
        req.SetUrl(url)
        req.SetType(.Get)
        if persistent {
            addingList[url] = ZUrlSession.DownloadPersistantlyToFileInThread(req, onCellular:onCellular, makeStatusCodeError:true) { [weak self] (response, furl, error) in
                self?.addingList[url] = nil
                if error != nil || furl == nil {
                    ZDebug.Print("ZUrlCache.GetUrl persistent: error:", error!.localizedDescription, url)
                } else {
                    file.Remove()
                    if let ferr = furl!.CopyTo(file) {
                        ZDebug.Print("ZUrlCache.GetUrl persistent copy: error:", ferr.localizedDescription, url)
                    }
                    furl!.Remove()
                }
            }
        } else {
            addingList[url] = ZUrlSession.Send(req, onMain:false, makeStatusCodeError:true) { [weak self] (response, data, error, sessionCount) in
                self?.addingList[url] = nil
                if error != nil {
                    ZDebug.Print("ZUrlCache.GetUrl: error:", error!.localizedDescription, url)
                } else {
                    if (data?.count)! < 300 {
                        ZDebug.Print("ZUrlCache.length:", data?.count)
                    }
                    if data?.SaveToFile(file) != nil {
                        ZDebug.Print("ZUrlCache.GetUrl: error saving file1:", url)
                        return
                    }
                    if file.DataSizeInBytes != response?.ContentLength {
                        ZDebug.Print("ZUrlCache.GetUrl: error saving file2:", url, "saved:", file.DataSizeInBytes, "url:", response?.ContentLength)
                        file.Remove()
                        return
                    }
                    //                ZDebug.Print("ZFileUrl.GotUrl:", url);
                }
            }
        }
        
        addingList[url] = ZUrlSession.Send(req, onMain:false, makeStatusCodeError:true) { [weak self] (response, data, error, sessionCount) in
            self?.addingList[url] = nil
            if error != nil {
                ZDebug.Print("ZUrlCache.GetUrl: error:", error!.localizedDescription, url)
            } else {
                if (data?.count)! < 300 {
                    ZDebug.Print("ZUrlCache.length:", data?.count)
                }
                if data?.SaveToFile(file) != nil {
                    ZDebug.Print("ZUrlCache.GetUrl: error saving file1:", url)
                    return
                }
                if file.DataSizeInBytes != response?.ContentLength {
                    ZDebug.Print("ZUrlCache.GetUrl: error saving file2:", url, "saved:", file.DataSizeInBytes, "url:", response?.ContentLength)
                    file.Remove()
                    return
                }
                //                ZDebug.Print("ZFileUrl.GotUrl:", url);
            }
        }
        return nil
    }
    
    func RemoveOld(_ hours:Double) {
        let time = ZTime.Now - hours * 60 * 60
        folder.Walk(options:.GetInfo) { (file, info) in
            if info.modified < time {
                file.Remove()
            }
            return true
        }
    }
    
    func RemoveAllExcept(keepUrls:[String]) {
        let keepFiles = Set(keepUrls.map({ makeFile(url:$0) }))
        var allFiles = Set<ZFileUrl>()
        folder.Walk(options:.GetInfo) { (file, info) in
            allFiles.insert(file)
            return true
        }
        let del = allFiles.subtracting(keepFiles)
        for f in del {
            f.Remove()
        }
    }
}
