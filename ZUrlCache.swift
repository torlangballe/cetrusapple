//
//  ZUrlCache.swift
//
//  Created by Tor Langballe on /2/12/15.
//

import Foundation

class ZUrlCache {
    var folder: ZFileUrl
    var persistent = false
    var onCellular:Bool? = nil
    var addExtensionAtEnd = true
    var defaultExtension = ""
    private var listMutex = ZMutex()
    private var addingList = [String:ZURLSessionTask]()

    init(name:String, removeOldHours:Double = 0, folderType:ZFolderType = .caches) {
        folder = ZFolders.GetFileInFolderType(folderType, addPath:name)
        if removeOldHours != 0 {
            RemoveOld(removeOldHours)
        }
        folder.CreateFolder()
        
        let preCachedFolder = ZGetResourceFileUrl("ZUrlCache/" + name)
        if preCachedFolder.Exists() {
            preCachedFolder.Walk() { (furl, finfo) in
                let name = furl.GetName()
                if let url = ZStr.UrlDecode(name) {
                    let file = MakeFile(url:url)
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
        listMutex.Lock()
        let getting = (addingList[url] != nil)
        listMutex.Unlock()
        return getting
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
    
    func MakeFile(url:String) -> ZFileUrl {
        //        let (base, _, stub, ext) = ZFileUrl.GetPathParts(url)
        //        let str = ZFileUrl.AbsString
        //        let str = ZStr.TruncateMiddle(base + stub, maxChars:100, separator:"…")
        var ext = ZUrl(string:url).Extension
        if ext.isEmpty {
            ext = defaultExtension
        }
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
        file = MakeFile(url:url)
        if file.Exists() {
            return true
        }
        return false
    }
    
    func FractionCompleted(_ url:String) -> Float? {
        if HasUrl(url) {
            return 1
        }
        listMutex.Lock()
        if let task = addingList[url] {
            listMutex.Unlock()
            return Float(task.FractionCompleted())
        }
        listMutex.Unlock()
        return nil
    }

    func StopDownload(url:String) {
        listMutex.Lock()
        if let task = addingList[url] {
            task.cancel()
            addingList.removeValue(forKey:url)
        }
        listMutex.Unlock()
    }

    func RemoveUrl(_ url:String) {
        listMutex.Lock()
        if let task = addingList[url] {
            task.cancel()
            addingList.removeValue(forKey:url)
        }
        listMutex.Unlock()
        let file = MakeFile(url:url)
        file.Remove()
    }

    @discardableResult func GetUrl(_ url:String) -> ZFileUrl? { // discardable since sometimes we want to just force-cache something
        if url.hasPrefix("https://polly.us-east-1.amazonaws.com") {
            print("polly url:", url)
        }
        var file = ZFileUrl()
        if HasFile(url, file:&file) {
            file.Modified = ZTime.Now()
            return file
        }
        listMutex.Lock()
        if addingList[url] != nil {
            listMutex.Unlock()
            return nil
        }
        let req = ZUrlRequest()
        req.SetUrl(url)
        req.SetType(.Get)
        if persistent {
            let t = ZInternet.DownloadPersistantlyToFileInThread(req, onCellular:onCellular, makeStatusCodeError:true) { [weak self] (response, furl, error) in
                self?.listMutex.Lock()
                self?.addingList[url] = nil
                self?.listMutex.Unlock()
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
            addingList[url] = t
            listMutex.Unlock()
            return  nil
        }
        let t = ZInternet.Send(req, onMain:false, makeStatusCodeError:true) { [weak self] (response, data, error, sessionCount) in
            self?.listMutex.Lock()
            self?.addingList[url] = nil
            self?.listMutex.Unlock()
            if error != nil {
                ZDebug.Print("ZUrlCache.GetUrl1: error:", error!.localizedDescription, url)
            } else {
                if (data?.count)! < 300 {
                    ZDebug.Print("ZUrlCache.length:", data?.count)
                }
                if data?.SaveToFile(file) != nil {
                    ZDebug.Print("ZUrlCache.GetUrl: error saving file1:", url)
                    return
                }
                if response?.ContentLength != -1 && file.DataSizeInBytes != response?.ContentLength {
                    ZDebug.Print("ZUrlCache.GetUrl: error saving file2:", url, "saved:", file.DataSizeInBytes, "url:", response?.ContentLength)
                    file.Remove()
                    return
                }
                //                ZDebug.Print("ZFileUrl.GotUrl:", url);
            }
        }
        addingList[url] = t
        listMutex.Unlock()
        return nil
    }
    
    func RemoveOld(_ hours:Double) {
        let time = ZTime.Now() - hours * ZTimeHour
        folder.Walk(options:.GetInfo) { (file, info) in
            if info.modified < time {
                if persistent {
                    ZDebug.Print("Cache.RemoveOld persistant:", file.AbsString)
                }
                file.Remove()
            }
            return true
        }
    }
    
    func RemoveAllExcept(keepUrls:[String]) {
        let keepFiles = Set(keepUrls.map({ MakeFile(url:$0) }))
        var allFiles = Set<ZFileUrl>()
        folder.Walk(options:.GetInfo) { (file, info) in
            allFiles.insert(file)
            return true
        }
        let del = allFiles.subtracting(keepFiles)
        for f in del {
            ZDebug.Print("Cache.RemoveAllExcept:", f.AbsString)
            f.Remove()
        }
    }
    
    func PrintDownloading() {
        listMutex.Lock()
        for (u, t) in addingList {
            print("Downloading:", t.FractionCompleted(), u)
        }
        listMutex.Unlock()
    }
}
