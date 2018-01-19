//
//  ZFileUrl.swift
//  Zed
//
//  Created by Tor Langballe on /31/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

private func dm() -> FileManager {
    return FileManager.default
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
    
    var FilePath : String {
        get { return url?.path ?? "" }
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
    
    func AppendedPath(_ path:String, isDir:Bool = false) -> ZFileUrl{
        return ZFileUrl(nsUrl:url!.appendingPathComponent(path, isDirectory:isDir))
        //        return path.stringByAppendingPathComponent("thisShouldBeTheNameOfTheFile")
    }
    
    static func GetLegalFilename(_ filename:String) -> String {
        var str = ZStrUtil.UrlEncode(filename)!
        if str.count > 200 {
            str = String(abs(filename.hashValue)) + "_" + ZStrUtil.Tail(str, chars:200)
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
}

struct ZFileInfo
{
    var dataSize = 0
    var created = ZTime.Null, modified = ZTime.Null, accessed = ZTime.Null
    var isLocked = false, isHidden = false, isFolder = false, isLink = false
}

extension ZFileUrl {
    func GetInfo( ) -> (ZFileInfo, Error?) {
        var info = ZFileInfo()
        if url == nil {
            return (info, ZError(message:"No file url"))
        }
        do {
            let dict = try dm().attributesOfItem(atPath: url!.path)
            info.dataSize = 0;
            info.created = dict[FileAttributeKey.creationDate] as? ZTime ?? ZTime.Null
            info.modified = dict[FileAttributeKey.modificationDate] as? ZTime ?? ZTime.Null
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
                try dm().setAttributes([FileAttributeKey.modificationDate:newValue], ofItemAtPath:url!.path)
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
}

extension ZFileUrl {
    struct WalkOptions : OptionSet {
        let rawValue: Int
        init(rawValue: Int) { self.rawValue = rawValue }
        static let None = WalkOptions(rawValue: 0)
        static let SubFolders = WalkOptions(rawValue: 1<<0)
        static let GetInfo = WalkOptions(rawValue: 1<<1)
        static let GetInvisible = WalkOptions(rawValue: 1<<1)
    }
    
    @discardableResult func Walk(options:WalkOptions = WalkOptions.None, wildcard:String? = nil, foreach:(ZFileUrl, ZFileInfo)->Bool) -> Error? {
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
                var err:Error? = nil
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
                    if !ZStrUtil.StrMatchsWildcard(name, wild:wildcard!) {
                        continue
                    }
                }
                if !foreach(file, info) {
                    break
                }
            }
        } else {
            return ZError(message:"ZFileUrl:Walk: Couldn't create enumerator")
        }
        
        return nil
    }
}
func |(a:ZFileUrl.WalkOptions, b:ZFileUrl.WalkOptions) -> ZFileUrl.WalkOptions { return ZFileUrl.WalkOptions(rawValue: a.rawValue | b.rawValue) }
func &(a:ZFileUrl.WalkOptions, b:ZFileUrl.WalkOptions) -> Bool       { return (a.rawValue & b.rawValue) != 0                  }

extension ZFileUrl {
    @discardableResult func CopyTo(_ to: ZFileUrl) -> Error? {
        do {
            try dm().copyItem(at: self.url! as URL, to:to.url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }

    @discardableResult func MoveTo(_ to: ZFileUrl) -> Error? {
        do {
            try dm().moveItem(at: self.url! as URL, to:to.url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }

    @discardableResult func LinkTo(_ to: ZFileUrl) -> Error? { // links self to to, i.e self becomes a hard link pointing to to
        do {
            try dm().linkItem(at: to.url! as URL, to:self.url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    @discardableResult func Remove() -> Error? {
        do {
            try dm().removeItem(at: url! as URL)
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    @discardableResult func RemoveContents() -> (Error?, [String]) {
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
}
