//
//  ZDebug.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation

extension ZDebug {
    static func Print(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
        var str = ""
        if ZDebug.lastStampTime.Since() > 3.0 {
            ZDebug.lastStampTime = ZTime.Now()
            str = ZDebug.lastStampTime.GetString(format:"============= yy-MM-dd' 'HH:mm:ssZZ =============\n")
        }
        for (i, item) in items.enumerated() {
            if i != 0 {
                str += separator
            }
            if item == nil {
                str += "<nil>"
            } else {
                str += "\(item!)"
            }
        }
        ZDebug.mutex.Lock()
        if !ZDebug.logAllOutput {
            if ZDebug.storePrintLines != 0 {
                if ZDebug.storedLines.count > ZDebug.storePrintLines {
                    ZDebug.storedLines.removeFirst()
                }
                ZDebug.storedLines.append(str)
            }
        }
        for h in ZDebug.printHooks {
            h(str)
        }
        ZDebug.mutex.Unlock()
        ZDebug.basePrint(str, terminator:terminator)
    }

    static func ErrorOnRelease() {
        if ZDebug.IsRelease() {
            var n = 100
            while n > 0 {
                ZDebug.Print("Should not run on ")
                n -= 1
            }
        }
    }

    static func LoadSavedLog(prefix:String) {
        let file = ZFolders.GetFileInFolderType(ZFolderType.temporary, addPath:prefix + "/zdebuglog.txt")
        let (str, _) = ZStr.LoadFromFile(file)
        ZDebug.storedLines = ZStr.Split(str, sep:"\n").writable()
    }

    static func AppendToFileAndClearLog(prefix:String) {
        let file = ZFolders.GetFileInFolderType(ZFolderType.temporary, addPath:prefix + "/zdebuglog.txt")
        
        if file.DataSizeInBytes > 5 * 1024 * 1024 {
            file.Remove()
            ZDebug.storedLines.insert("--- ZDebug.Cleared early part of large stored log.", at:0)
        }
// #swift-only:
        let (stream, err) = file.OpenOutput(append:true)
        if err != nil || stream == nil {
            print("ZDebug.AppendToFileAndClearLog open err:", err?.localizedDescription ?? "")
            return
        }
        for s in ZDebug.storedLines {
            let a = [UInt8](ZStr.Utf8(s))
            if stream!.write(a, maxLength: a.count) != a.count {
                print("ZDebug.AppendToFileAndClearLog error writing.")
                return
            }
            stream!.write([UInt8](ZStr.Utf8("\n")), maxLength:1)
        }
// #end
        ZDebug.storedLines.removeAll()
    }
}

