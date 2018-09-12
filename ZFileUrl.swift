//
//  ZFileUrl.swift
//  Zed
//
//  Created by Tor Langballe on /31/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZOutputStream = OutputStream

struct ZFileInfo
{
    var dataSize = 0
    var created = ZTimeNull, modified = ZTimeNull, accessed = ZTimeNull
    var isLocked = false, isHidden = false, isFolder = false, isLink = false
}

class ZFileUrl : ZUrl {
    init(filePath:String, isDir:Bool = false, dirUnknow:Bool = false) {
        let vfilePath = NSString(string:filePath).expandingTildeInPath
        super.init()
        if dirUnknow {
            url = URL(fileURLWithPath:vfilePath)
        } else {
            url = URL(fileURLWithPath:vfilePath, isDirectory:isDir)
        }
    }

    override init() {
        super.init()
    }

    override init(string:String) {
        super.init(string:string)
    }

    override init(url:ZUrl) {
        super.init(url:url)
    }
    
    override init(nsUrl:URL) {
        super.init(nsUrl:nsUrl)
    }
    
//    required init(from decoder: Decoder) throws {
//        try super.init(from:decoder)
//    }
//    
    var FilePath : String {
        get {
            let str = url?.path ?? ""
            if IsFolder() && ZStr.Tail(str) != "/" {
                return str + "/"
            }
            return str
        }
    }

    func OpenOutput(append:Bool = false) -> (ZOutputStream?, ZError?) {
        if let stream = OutputStream(url:url!, append:append) {
            stream.open()
            return (stream, stream.streamError)
        }
        return (nil, ZNewError("couldn't make stream"))
    }
    
    func IsFolder() -> Bool {
        return IsDirectory()
    }
    
    func Exists() -> Bool {
        if url != nil {
            let exists = dm().fileExists(atPath: url!.path)
            return exists
        }
        return false
    }
    
    @discardableResult func CreateFolder() -> Bool {
        if url != nil {
            if Exists() && IsFolder() {
                return true
            }
            do {
                try dm().createDirectory(atPath: url!.path, withIntermediateDirectories:false, attributes:nil)
                return true
            } catch {}
        }
        return false;
    }
    
    func GetDisplayName() -> String {
        if url != nil {
            return dm().displayName(atPath: url!.path)
        }
        return ""
    }
    
    static func GetLegalFilename(_ filename:String) -> String {
        var str = ZStr.UrlEncode(filename)!
        if str.count > 200 {
            str = String(abs(filename.hashValue)) + "_" + ZStr.Tail(str, chars:200)
        }
        return str
    }
    
    static func GetPathParts(_ path:String) -> (String, String, String, String) { // place/a.txt = "place" "a.txt" "a" ".txt"
        if let url = URL(string:path) {
            let fullname = url.lastPathComponent
            var base = ""
            if fullname != path {
                base = url.deletingLastPathComponent().absoluteString
            }
            let ext = "." + url.pathExtension
            let stub = NSString(string:fullname).deletingPathExtension
            return (base, fullname, stub, ext)
        }
        return ("", "", "", "")
    }

    func GetInfo( ) -> (ZFileInfo, ZError?) {
        var info = ZFileInfo()
        if url == nil {
            return (info, ZNewError("No file url"))
        }
        do {
            let dict = try dm().attributesOfItem(atPath: url!.path)
            info.dataSize = 0;
            info.created = dict[FileAttributeKey.creationDate] as? ZTime ?? ZTimeNull
            info.modified = dict[FileAttributeKey.modificationDate] as? ZTime ?? ZTimeNull
            info.isLocked = dict[FileAttributeKey.immutable] as? Bool ?? false
            //            info.isHidden = dict[FileAttributeKey URLResourceKey.isHiddenKey] as? Bool ?? false // extensionHidden ??
            
            if let type = dict[FileAttributeKey.type] as? FileAttributeType {
                info.isFolder = (type == .typeDirectory)
                info.isLink = (type == .typeSymbolicLink)
            }
            if !info.isFolder {
                if let n = dict[FileAttributeKey.size] as? NSNumber {
                    info.dataSize = Int(n.int64Value)
                }
            }
        } catch let error {
            return (info, error)
        }
        return (info, nil)
    }
    
    var Modified: ZTime {
        get {
            let (info, err) = GetInfo()
            if err == nil {
                return info.modified
            }
            return ZTime()
        }
        set {
            do {
                try dm().setAttributes([FileAttributeKey.modificationDate:newValue.date], ofItemAtPath:url!.path)
            } catch let error as NSError {
                ZDebug.Print("ZFileUrl set modified error:", error.description)
            }
        }
    }

    var Created: ZTime {
        let (info, err) = GetInfo()
        if err == nil {
            return info.created
        }
        return ZTime()
    }

    var DataSizeInBytes: Int {
        let (info, err) = GetInfo()
        if err == nil {
            return info.dataSize
        }
        return -1
    }

    enum WalkOptions:Int { case None = 0, SubFolders = 1, GetInfo = 2, GetInvisible = 4 }
    
    @discardableResult func Walk(options:WalkOptions = WalkOptions.None, wildcard:String? = nil, foreach:(ZFileUrl, ZFileInfo)->Bool) -> ZError? {
        if url == nil {
            return nil
        }
        var nsOptions = FileManager.DirectoryEnumerationOptions()
        
        if !(options & .SubFolders) {
            nsOptions.insert(FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants)
        }
        if options & .GetInvisible {
            nsOptions.insert(FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        }
        if let nsEnum = dm().enumerator(at: url! as URL, includingPropertiesForKeys:[URLResourceKey.typeIdentifierKey], options:nsOptions, errorHandler:nil) {
            while let nsurl = nsEnum.nextObject() as? URL {
                var info = ZFileInfo()
                var err:ZError? = nil
                //                let isDir = (nsEnum.fileAttributes![NSFileType]?.string == NSFileTypeDirectory)
                let file = ZFileUrl(nsUrl: nsurl)
                //            file = self.AppendedPath(name, isDir:isDir)
                //                if (options & WalkOptions.SubFolders.rawValue) == 0 && isDir {
                //                    nsEnum.skipDescendents()
                //                }
                let name = file.GetName()
                if !(options & .GetInvisible) && name.hasPrefix(".") {
                    continue
                }
                if (options & .GetInfo) {
                    (info, err) = file.GetInfo()
                    if err != nil {
                        ZDebug.Print("ZFuleUrl.Walk err:", err, file)
                    }
                }
                if wildcard != nil {
                    if !ZStr.StrMatchsWildcard(name, wild:wildcard!) {
                        continue
                    }
                }
                if !foreach(file.ResolveSimlinkOrSelf(), info) {
                    break
                }
            }
        } else {
            return ZNewError("ZFileUrl:Walk: Couldn't create enumerator")
        }
        
        return nil
    }

    @discardableResult func CopyTo(_ to: ZFileUrl) -> ZError? {
        do {
            try dm().copyItem(at: self.url! as URL, to:to.url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }

    @discardableResult func MoveTo(_ to: ZFileUrl) -> ZError? {
        do {
            try dm().moveItem(at: self.url! as URL, to:to.url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }

    @discardableResult func LinkTo(_ to: ZFileUrl) -> ZError? { // links self to to, i.e self becomes a hard link pointing to to
        do {
            try dm().linkItem(at: to.url! as URL, to:self.url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    func ResolveSimlinkOrSelf() -> ZFileUrl {
        if url == nil {
            return self
        }
        let resolved = url?.resolvingSymlinksInPath() ?? nil
        if resolved == nil {
            return self
        }
        return ZFileUrl(nsUrl:resolved!)
    }

    @discardableResult func Remove() -> ZError? {
        do {
            try dm().removeItem(at: url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    @discardableResult func RemoveContents() -> (ZError?, [String]) {
        var errors = [String]()
        var paths = [String]()
        let fm = dm()
        if let folderPath = url?.path {
            do {
                paths = try fm.contentsOfDirectory(atPath: folderPath)
            } catch let error as NSError {
                return (error, errors)
            }
            for path in paths {
                do {
                try fm.removeItem(atPath: "\(folderPath)/\(path)")
                } catch let error as NSError {
                    errors.append(error.localizedDescription + " : " + path)
                }
            }
        }
        return (nil, errors)
    }

    func AppendedPath(_ path:String, isDir:Bool = false) -> ZFileUrl{
        return ZFileUrl(nsUrl:url!.appendingPathComponent(path, isDirectory:isDir))
    }
}

private func dm() -> FileManager {
    return FileManager.default
}

func |(a:ZFileUrl.WalkOptions, b:ZFileUrl.WalkOptions) -> ZFileUrl.WalkOptions { return ZFileUrl.WalkOptions(rawValue: a.rawValue | b.rawValue)! }
func &(a:ZFileUrl.WalkOptions, b:ZFileUrl.WalkOptions) -> Bool { return (a.rawValue & b.rawValue) != 0 }


