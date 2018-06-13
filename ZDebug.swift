//
//  ZDebug.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

struct ZDebug {
    static let mutex = ZMutex()
    static var storePrintLines = 0
    static var storedLines = [String]()
    static var lastStampTime = ZTime.Null
    static var printHooks = [(String)->()]()

    static func Print(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
        var str = ""
        if ZTime.UpdateIfOlderThanSecs(3, time:&lastStampTime) {
            str = lastStampTime.GetString(format:"============= yy-MM-dd' 'HH:mm:ssZZ =============\n")
        }
        for (i, item) in items.enumerated() {
            if i != 0 {
                str += separator
            }
            str += String(describing: item ?? "<nil>")
        }
        mutex.Lock()
        if ZDebug.storePrintLines != 0 {
            if ZDebug.storedLines.count > ZDebug.storePrintLines {
                ZDebug.storedLines.removeFirst()
            }
            ZDebug.storedLines.append(str)
        }
        for h in printHooks {
            h(str)
        }
        mutex.Unlock()
        print(str, terminator:terminator)
    }

    static func ErrorOnRelease() {
        if IsRelease() {
            for _ in 1...100 {
                Print("Should not run on ")
            }
        }
    }
    
    static func IsRelease() -> Bool {
        return !_isDebugAssertConfiguration()
    }
    
    static func IsMinIOS11() -> Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }

    static func LoadSavedLog(prefix:String) {
        let file = ZFolders.GetFileInFolderType(.temporary, addPath:prefix + "/zdebuglog.txt")
        let (str, _) = ZStrUtil.LoadFromFile(file)
        storedLines = ZStrUtil.Split(str, sep:"\n")
    }

    static func AppendToFileAndClearLog(prefix:String) {
        let file = ZFolders.GetFileInFolderType(.temporary, addPath:prefix + "/zdebuglog.txt")
        
        if file.DataSizeInBytes > 5 * 1024 * 1024 {
            file.Remove()
            ZDebug.storedLines.insert("--- ZDebug.Cleared early part of large stored log.", at:0)
        }
        let (stream, err) = file.OpenOutput(append:true)
        if err != nil || stream == nil {
            print("ZDebug.AppendToFileAndClearLog open err:", err?.localizedDescription ?? "")
            return
        }
        for s in ZDebug.storedLines {
            let a = [UInt8](s.utf8)
            if stream!.write(a, maxLength: a.count) != a.count {
                print("ZDebug.AppendToFileAndClearLog error writing.")
                return
            }
            stream!.write([UInt8]("\n".utf8), maxLength:1)
        }
        ZDebug.storedLines.removeAll()
    }
}

