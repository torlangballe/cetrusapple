//
//  ZInternet.Apple.swift
//
//  Created by Tor Langballe on 11/15/18.
//

import Foundation

class ZIPAddress {
    var ip4String = "127.0.0.1"
    func GetIp4String() -> String {
        return ip4String
    }
        
    init(ip4String:String = "") {
        self.ip4String = ip4String
    }
}

struct ZInternet {
    static func ResolveAddress(_ address:String) -> ZIPAddress {
        let ip = ZIPAddress(ip4String: "127.0.0.1")
        return ip
    }
    
    static func GetNetworkTrafficBytes(processUid:Int? = nil) -> Int64 {
        let info = DataUsage.getDataUsage()
        return Int64(info.wifiReceived)
    }
    
    static func PingAddressForLatency(_ ipAddress:ZIPAddress) -> Double? {
        return ZMath.Random1() + 0.1
    }
}

class ZRateLimiter {
    let max:Int
    let durationSecs:Double
    
    var timeStamps = [ZTime]()
    init(max:Int, durationSecs:Double) {
        self.max = max
        self.durationSecs = durationSecs
    }
    
    func Add() {
        timeStamps.append(ZTime.Now())
    }
    
    func IsExceded() -> Bool {
        timeStamps.removeIf { $0.Since() > durationSecs  }
        return timeStamps.count >= max
    }
}

struct DataUsageInfo {
    var wifiReceived: UInt32 = 0
    var wifiSent: UInt32 = 0
    var wirelessWanDataReceived: UInt32 = 0
    var wirelessWanDataSent: UInt32 = 0
    
    mutating func updateInfoByAdding(_ info: DataUsageInfo) {
        wifiSent += info.wifiSent
        wifiReceived += info.wifiReceived
        wirelessWanDataSent += info.wirelessWanDataSent
        wirelessWanDataReceived += info.wirelessWanDataReceived
    }
}

class DataUsage {
    private static let wwanInterfacePrefix = "pdp_ip"
    private static let wifiInterfacePrefix = "en"
    
    class func getDataUsage() -> DataUsageInfo {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var dataUsageInfo = DataUsageInfo()
        
        guard getifaddrs(&ifaddr) == 0 else { return dataUsageInfo }
        while let addr = ifaddr {
            guard let info = getDataUsageInfo(from: addr) else {
                ifaddr = addr.pointee.ifa_next
                continue
            }
            dataUsageInfo.updateInfoByAdding(info)
            ifaddr = addr.pointee.ifa_next
        }
        
        freeifaddrs(ifaddr)
        
        return dataUsageInfo
    }
    
    private class func getDataUsageInfo(from infoPointer: UnsafeMutablePointer<ifaddrs>) -> DataUsageInfo? {
        let pointer = infoPointer
        let name: String! = String(cString: pointer.pointee.ifa_name)
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        
        return dataUsageInfo(from: pointer, name: name)
    }
    
    private class func dataUsageInfo(from pointer: UnsafeMutablePointer<ifaddrs>, name: String) -> DataUsageInfo {
        var networkData: UnsafeMutablePointer<if_data>?
        var dataUsageInfo = DataUsageInfo()
        
        if name.hasPrefix(wifiInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wifiSent += data.pointee.ifi_obytes
                dataUsageInfo.wifiReceived += data.pointee.ifi_ibytes
            }
            
        } else if name.hasPrefix(wwanInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wirelessWanDataSent += data.pointee.ifi_obytes
                dataUsageInfo.wirelessWanDataReceived += data.pointee.ifi_ibytes
            }
        }
        
        return dataUsageInfo
    }
}

