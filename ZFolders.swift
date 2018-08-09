//
//  ZFolders.swift
//  Zed
//
//  Created by Tor Langballe on /30/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

struct ZFolders {
    enum FolderType: Int {
        case preferences = 1
        case resources = 2
        case caches = 4
        case temporary = 8
        case appSupport = 16
        case preferencesOrResources = 64
        case newestOfPreferencesOrResources = 128
        case temporaryUniqueFolder = 256
    }
    static func GetFileInFolderType(_ type:FolderType, addPath:String = "") -> ZFileUrl {
        
        if type == .preferencesOrResources {
            let fp = GetFileInFolderType(.preferences, addPath:addPath)
            if fp.Exists() {
                return fp
            }
            return GetFileInFolderType(.resources, addPath:addPath)
        }
        if type == .newestOfPreferencesOrResources {
            let fp = GetFileInFolderType(.preferences, addPath:addPath)
            let fr = GetFileInFolderType(.resources, addPath:addPath)
            if !fp.Exists() {
                return fr
            }
            if !fr.Exists() {
                return fp
            }
            if fr.Modified > fp.Modified {
                return fr
            }
            return fp
        }
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

                case .resources: // this actually uses bundle pathForResource method, so it can get resources NOT in normal resource folder such as on-demand stuff
                    if addPath.isEmpty {
                        return ZFileUrl(nsUrl:Bundle.main.bundleURL)
                    }
                    var (base, _, stub, ext) = ZFileUrl.GetPathParts(addPath)
                    ext = ZStr.Body(ext, pos:1)
                    if let respath = Bundle.main.path(forResource: stub, ofType:ext, inDirectory:base) {
                        return ZFileUrl(filePath:respath)
                    }
                    return ZFileUrl()
                //                    nsUrl = NSBundle.mainBundle().resourceURL ?? NSURL()
  
                case .preferences:
                    nsUrl = URL(fileURLWithPath:NSString(string:"~/Library/").expandingTildeInPath)
                
                default: break
            }
        } catch {}
        
        if !addPath.isEmpty {
            nsUrl = nsUrl?.appendingPathComponent(addPath)
        }
        return ZFileUrl(nsUrl:nsUrl!)
    }
}
