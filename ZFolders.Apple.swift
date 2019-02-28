//
//  ZFolders.swift
//  Zed
//
//  Created by Tor Langballe on /30/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

enum ZFolderType: Int {
    case preferences = 1
    case caches = 4
    case temporary = 8
    case appSupport = 16
    case temporaryUniqueFolder = 256
}

struct ZFolders {
    static func GetFileInFolderType(_ type:ZFolderType, addPath:String = "") -> ZFileUrl {
        if type == .temporaryUniqueFolder {
            let str = String(10000 + ZMath.RandomN(10000))
            let folder = GetFileInFolderType(.temporary, addPath:str)
            folder.CreateFolder()
            return folder.AppendedPath(addPath)
        }
        
        var nsUrl = URL(string:"")
        do {
            switch type {
                case .appSupport:
                    nsUrl = try FileManager.default.url(for: .applicationSupportDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            
                case .caches:
                    nsUrl = try FileManager.default.url(for: .cachesDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                
                case .temporary:
                    let stemp = NSTemporaryDirectory()
                    nsUrl = URL(fileURLWithPath:stemp, isDirectory:true)

                case .preferences:
                    let appId = Bundle.main.bundleIdentifier ?? ""
                    nsUrl = URL(fileURLWithPath:NSString(string:"~/Library/Preferences/" + appId).expandingTildeInPath)
                    ZFileUrl(nsUrl:nsUrl!).CreateFolder()
                
                default: break
            }
        } catch {}
        
        if !addPath.isEmpty {
            nsUrl = nsUrl?.appendingPathComponent(addPath)
        }
        return ZFileUrl(nsUrl:nsUrl!)
    }
}

func ZGetResourceFileUrl(_ subPath:String) -> ZFileUrl {
    if subPath.isEmpty {
        return ZFileUrl(nsUrl:Bundle.main.bundleURL)
    }
    let (base, stub, ext) = ZFileUrl.GetPathParts(subPath)
    if let respath = Bundle.main.path(forResource: stub, ofType:ext, inDirectory:base) {
        return ZFileUrl(filePath:respath)
    }
    return ZFileUrl()
}
