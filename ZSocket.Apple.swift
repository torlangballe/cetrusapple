//
//  ZSocket.Apple.swift
//  BoxProbe
//
//  Created by Tor Langballe on 31/01/2019.
//  Copyright © 2019 Bridge Technologies. All rights reserved.
//

import Foundation

typealias ZSocket = CFSocket

extension ZSocket {
    static func MakeUDP(address:ZIPAddress, port:Int) -> (ZSocket?, ZError?) {
        let inAddr = inet_addr(address.GetIp4String())
        if inAddr == INADDR_NONE {
            return (nil, ZNewError("no valid dddress"))
        }
        let socket = CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, nil, nil)
        if socket == nil {
            return (nil, ZNewError("socket creation failed"))
        }
        var sin = sockaddr_in() // https://linux.die.net/man/7/ip
        sin.sin_len = __uint8_t(MemoryLayout.size(ofValue: sin))
        sin.sin_family = sa_family_t(AF_INET)
        sin.sin_port = UInt16(port).bigEndian
        sin.sin_addr.s_addr = inAddr
        
        let addressDataCF = NSData(bytes: &sin, length: MemoryLayout.size(ofValue: sin)) as CFData
        
        let err = CFSocketConnectToAddress(socket, addressDataCF, 10)
        if err != .success {
            return (nil, ZNewError("set address error code: \(err.rawValue)"))
        }
        return (socket, nil)
    }

    static func SendWithUDP(address:ZIPAddress, port:Int, data:ZData) -> ZError? {
        let (socket, err) = ZSocket.MakeUDP(address:address, port:port)
        if err == nil {
            return socket!.SendWithUDP(data:data)
        }
        return err
    }

    func SendWithUDP(data:ZData) -> ZError? {
        var err: CFSocketError = .error
        data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>)->Void in
            let cfData = CFDataCreate(kCFAllocatorDefault, bytes, data.count)
            err = CFSocketSendData(self, nil, cfData, 0)
        }
        if err != .success {
            return ZNewError("send error code: \(err.rawValue)")
        }
        return nil
    }
}

