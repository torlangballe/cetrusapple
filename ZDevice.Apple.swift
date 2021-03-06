//
//  ZDevice.swift
//
//  Created by Tor Langballe on /24/11/15.
//

// #package com.github.torlangballe.cetrusandroid

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
    
    static var DeviceName: String {
        return UIDevice.current.name
        //mac:    nsstr = [(NSString *)SCDynamicStoreCopyComputerName(NULL, NULL) autorelease];  //  NSString *localHostname = [(NSString *)SCDynamicStoreCopyLocalHostName(NULL) autorelease];
    }
    
    static var IdentifierForVendor: String? {
        return UIDevice.current.identifierForVendor!.uuidString
        //mac: ZStrLowerCased(ZEthernet::GetMainMACAddress().GetStripped(":"));
    }
    
    static var BatteryLevel: Float {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
        #else
        return 1
        #endif
    }
    
    static var IsDeviceCharging: Int { // return's -1 if unknown
        #if os(iOS)
        switch UIDevice.current.batteryState {
        case UIDevice.BatteryState.unplugged  : return 0
        case UIDevice.BatteryState.charging   : return 1
        case UIDevice.BatteryState.full       : return 1
        default                              : return -1
        }
        #else
        return 0
        #endif
    }
    
    static func FreeAndUsedDiskSpace() -> (Int64, Int64) {
        return (1024 * 1024 * 300, 1024 * 1024 * 32)
    }
    
    static var OSVersionString: String {
        return UIDevice.current.systemVersion
    }
    
    static var TimeZone: ZTimeZone {
        return ZTimeZone.DeviceZone
    }
    
    static var FingerPrint: String {
        return ""
    }
    
    static var Manufacturer: String {
        return "Apple"
    }
    
    static var DeviceType: String {
        let n = DeviceCodeNumbered
        return "\(n.0)\(n.1)\(n.2)"
    }
    
    static var HardwareModel: String {
        return ""
    }
    
    static var HardwareType: String {
        let n = DeviceCodeNumbered
        if ZIsTVBox() {
            if ZIsRunningInSimulator() {
                return "TV Simulator"
            }
            return "TV"
        }
        return n.0
    }
    
    static var HardwareBrand: String {
        return "Apple"
    }
    
    static func IsWifiEnabled() -> Bool {
        return false
    }
    
    static func GetWifiIPv4Address() -> String {
        // https://stackoverflow.com/questions/30748480/swift-get-devices-wifi-ip-address/30754194#30754194
        var address = ""
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "" }
        guard let firstAddr = ifaddr else { return "" }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    static func GetIPv6Address() -> String {
        return ""
    }
    
    static func GetMainMAC() -> UInt64 {
        #if os(tvOS)
        return GetLanMAC()
        #else
        return GetWifiMAC()
        #endif
    }
    
    static func GetWifiMAC() -> UInt64 {
        return 0x112233445567
    }
    
    static func GetLanMAC() -> UInt64 {
        return 0x112233445566
    }
    
    static func GetNetworkType() -> String {
        return ""
    }
    
    static func GetWifiLinkSpeed() -> String {
        return ""
    }
    
    static var DeviceCodeNumbered: (String, Int, String, String) { // fullname, version(52), text-only-name, known-as
        var systemInfo = utsname()
        var knownAs = ""
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        knownAs = identifier
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
    
    static func GetMemoryFreeAndUsed() -> (Int64, Int64) {
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
        
        return (mfree, mused)
    }
    
    static func GetNetworkSSIDs() -> [String] {
        #if os(iOS)
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
        #else
        return []
        #endif
    }
    
    static func GetCpuUsage() -> [Double] {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t
        var cpu = [Double]()
        
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))
        
        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return []
        }
        
        var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
        var thread_count: mach_msg_type_number_t = 0
        defer {
            if let thread_list = thread_list {
                vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
            }
        }
        
        kr = task_threads(mach_task_self_, &thread_list, &thread_count)
        
        if kr != KERN_SUCCESS {
            return []
        }
        
        if let thread_list = thread_list {
            
            for j in 0 ..< Int(thread_count) {
                var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
                kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                                 &thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    return []
                }
                
                let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)
                
                if threadBasicInfo.flags != TH_FLAGS_IDLE {
                    cpu.append((Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0)
                }
            } // for each thread
        }
        
        return cpu
    }
    
    static fileprivate func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
        var result = thread_basic_info()
        result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
        result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
        result.cpu_usage = threadInfo[4]
        result.policy = threadInfo[5]
        result.run_state = threadInfo[6]
        result.flags = threadInfo[7]
        result.suspend_count = threadInfo[8]
        result.sleep_time = threadInfo[9]
        return result
    }
}

