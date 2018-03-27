//
//  ZCues.swift
//  cetrus
//
//  Created by Tor Langballe on /23/3/18.
//

import Foundation

struct ZCue : Codable {
    enum CueType:String { case inlineSpeech = "inspeech", inlineTitle = "intitle", inlineUrl = "inurl", inlineImageUrl = "inimageurl", audioRange = "audiorange", chapter = "chapter", audioLine = "audioline", url = "url" }
    
    var type = ""
    var start = 0.0
    var end = 0.0
    var string:String? = nil
    var url:String? = nil
    var locale:String? = nil
}

class ZCues {
    var list = [ZCue]()
    
    func MergeFromFile(file:ZFileUrl, chapters:Bool = false, speech:Bool = false, audioLines:Bool = false, got:(_ error:ZError?)->Void) {
        
    }
}

class ZAllCues {
    var map = [String:ZCues]()
    let initMutex = ZMutex()
    let folder:ZFileUrl

    init(folderName:String = "zcues") {
        folder = ZFolders.GetFileInFolderType(.preferences, addPath:folderName)
    }
    
    func LoadFromFolder() {
        initMutex.Lock()
        ZBackgroundParallellQue.async { [weak self] () in
            self?.folder.Walk { [weak self] file, info in
                if let data = ZJSONData(fileUrl:file) {
                    let cs = ZCues()
                    let err = data.Decode(&cs.list)
                    if err != nil {
                        ZDebug.Print("ZCues.LoadFromFolder err:", err!.localizedDescription, file.AbsString)
                    } else {
                        var url = ""
                        for c in cs.list {
                            if c.type == ZCue.CueType.url.rawValue {
                                url = c.string ?? ""
                            }
                        }
                        if !url.isEmpty {
                            self!.map[url] = cs
                        }
                    }
                }
                return true
            }
            self?.initMutex.Unlock()
        }
    }
}


