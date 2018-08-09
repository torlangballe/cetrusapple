//
//  ZDevice.swift
//  capsulefm
//
//  Created by Tor Langballe on /24/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration.CaptiveNetwork

struct ZDevice {
    enum RemoveCommand:Int {
        case togglePlaypause
        case play
        case pause
        case nextTrack
        case stop
        case previousTrack
        case beginSeekingBackward
        case endSeekingBackward
        case beginSeekingForward
        case endSeekingForward
    }

    static var IsIPad:Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }

    static var IsIPhone:Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }

//    static func SetDisableIdleSleep(_ disable:Bool) { this is done in ZScreen
//        UIApplication.shared.isIdleTimerDisabled = disable
//    }
//
    static var DeviceName: String {
        return UIDevice.current.name
        //mac:    nsstr = [(NSString *)SCDynamicStoreCopyComputerName(NULL, NULL) autorelease];  //  NSString *localHostname = [(NSString *)SCDynamicStoreCopyLocalHostName(NULL) autorelease];
    }
    
    static var IdentifierForVendor: String? {
        return UIDevice.current.identifierForVendor!.uuidString
        //mac: ZStrLowerCased(ZEthernet::GetMainMACAddress().GetStripped(":"));
    }
    
    static var BatteryLevel: Float {
        // #if TARGET_IPHONE_SIMULATOR
        // return 1.0;
        // #endif
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }
    
    static var IsDeviceCharging: Int { // return's -1 if unknown
        switch UIDevice.current.batteryState {
            case UIDeviceBatteryState.unplugged  : return 0
            case UIDeviceBatteryState.charging   : return 1
            case UIDeviceBatteryState.full       : return 1
            default                              : return -1
        }
    }
    
//    static var IdleSleepEnabled: Bool { // done in screen
//        get {
//            return !UIApplication.shared.isIdleTimerDisabled
//        }
//        set {
//            UIApplication.shared.isIdleTimerDisabled = !newValue
//        }
//    }
//
    
    static var FreeAndUsedDiskSpace: (Int, Int) {
        return (1024 * 1024 * 300, 1024 * 1024 * 32)
    }
    
    static var OSVersionString: String {
        return UIDevice.current.systemVersion
    }
    
    static var TimeZone: ZTimeZone {
        return ZTimeZone.DeviceZone
    }

    static var DeviceType: (String, Int, String, String) { // fullname, version(52), text-only-name, known-as
        var systemInfo = utsname()
        var knownAs = ""
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 knownAs = "iPod Touch 5"
        case "iPod7,1":                                 knownAs = "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     knownAs = "iPhone 4"
        case "iPhone4,1":                               knownAs = "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  knownAs = "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  knownAs = "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  knownAs = "iPhone 5s"
        case "iPhone7,2":                               knownAs = "iPhone 6"
        case "iPhone7,1":                               knownAs = "iPhone 6 Plus"
        case "iPhone8,1":                               knownAs = "iPhone 6s"
        case "iPhone8,2":                               knownAs = "iPhone 6s Plus"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":knownAs = "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           knownAs = "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           knownAs = "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           knownAs = "iPad Air"
        case "iPad5,3", "iPad5,4":                      knownAs = "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           knownAs = "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           knownAs = "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           knownAs = "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      knownAs = "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      knownAs = "iPad Pro"
        case "AppleTV5,3":                              knownAs = "Apple TV"
        case "i386", "x86_64":                          knownAs = "Simulator"
        default:                                        knownAs = identifier
        }
        var version = 0
        var (name, sv2) = ZStr.SplitInTwo(identifier, sep:",")
        if sv2 != "" {
            let i = ZStr.FindFirstOfChars(name, charset:"0123456789")
            if i != -1 {
                let v1 = Int(ZStr.Body(name, pos:i)) ?? 0
                name = ZStr.Head(name, chars:i)
                version = Int(sv2) ?? 0
                version += v1 * 10
            }
        }
        return (identifier, version, name, knownAs)
    }
    
    static func GetMemoryUsedAndFree() -> (Int64, Int64) {
        var pagesize: vm_size_t = 0
        let host_port: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
                    ZDebug.Print("Error: Failed to fetch vm statistics")
                }
            }
        }
        let mused = Int64(vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * Int64(pagesize)
        let mfree = Int64(vm_stat.free_count) * Int64(pagesize)
        
        return (mused, mfree)
    }

    static func GetNetworkSSIDs() -> [String] {
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        return interfaceNames.flatMap { name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            return ssid
        }
    }
    /*
        
        void ZTurnOnFlash(bool on)
        {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
        
        [device lockForConfiguration:nil];
        if (on) {
        [device setTorchMode:AVCaptureTorchModeOn];
        [device setFlashMode:AVCaptureFlashModeOn];
        //torchIsOn = YES; //define as a variable/property if you need to know status
        } else {
        [device setTorchMode:AVCaptureTorchModeOff];
        [device setFlashMode:AVCaptureFlashModeOff];
        //torchIsOn = NO;
        }
        [device unlockForConfiguration];
        }
        }
        }
        */
}
