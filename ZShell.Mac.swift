//
//  ZShell.Mac.swift
//  Andrios
//
//  Created by Tor Langballe on 20/02/2019.
//  Copyright © 2019 Tor Langballe. All rights reserved.
//

import AppKit

class ZShell {
    @discardableResult static func RunCommand(_ path: String, args: [String], output:Bool = false) -> String {
        let pipe = Pipe()
        let task = Process()
        task.launchPath = path
        task.arguments = args
        task.standardOutput = pipe
        let file = pipe.fileHandleForReading
        task.launch()
        if output {
            if let result = NSString(data: file.readDataToEndOfFile(), encoding: String.Encoding.utf8.rawValue) {
                return result as String
            }
        }
        return ""
    }

    static func getAppFile(_ name: String) -> ZFileUrl {
        var f = ZFileUrl()
        if name.hasPrefix("/") || name.hasPrefix("~") {
            f = ZFileUrl(filePath: name)
        } else {
            let workspace = NSWorkspace.shared
            f = ZFileUrl(filePath: workspace.fullPath(forApplication: name)!)
        }
        return f
    }
    @discardableResult static func OpenApp(_ name: String, args: [String]) -> ZError? {
        let workspace = NSWorkspace.shared
        let f = getAppFile(name)
        do {
            try workspace.launchApplication(at: f.url!, configuration: [NSWorkspace.LaunchConfigurationKey.arguments : args])
        } catch let error {
            return error
        }
        return nil
    }

    @discardableResult static func OpenFilesWithApp(_ appName: String, files: [ZFileUrl]) -> ZError? {
        let workspace = NSWorkspace.shared
        let urls = files.map { $0.url! }
        let f = getAppFile(appName)
        do {
            try workspace.open(urls, withApplicationAt: f.url!, options: NSWorkspace.LaunchOptions(), configuration: [:])
        } catch let error {
            return error
        }
        return nil
    }
    
    @discardableResult static func ShowFileInViewer(_ file: ZFileUrl) -> ZError? {
        if !NSWorkspace.shared.selectFile(file.FilePath, inFileViewerRootedAtPath: "") {
            return ZNewError("failed")
        }
        return nil
    }
}

