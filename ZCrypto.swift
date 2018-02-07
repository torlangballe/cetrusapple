//
//  ZCrypto.swift
//  capsulefm
//
//  Created by Tor Langballe on /12/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

enum HMACAlgorithm {
    case md5, sha1, sha224, sha256, sha384, sha512
    
    func toCCEnum() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .md5   : result = kCCHmacAlgMD5
        case .sha1  : result = kCCHmacAlgSHA1
        case .sha224: result = kCCHmacAlgSHA224
        case .sha256: result = kCCHmacAlgSHA256
        case .sha384: result = kCCHmacAlgSHA384
        case .sha512: result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .md5    : result = CC_MD5_DIGEST_LENGTH
        case .sha1   : result = CC_SHA1_DIGEST_LENGTH
        case .sha224 : result = CC_SHA224_DIGEST_LENGTH
        case .sha256 : result = CC_SHA256_DIGEST_LENGTH
        case .sha384 : result = CC_SHA384_DIGEST_LENGTH
        case .sha512 : result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

struct ZCrypto {
    
    static func HmacSha1ToBase64(_ data:String, key:String) -> String {
        let str = data.cString(using: String.Encoding.utf8)
        let algorithm = HMACAlgorithm.sha1
        let strLen = data.lengthOfBytes(using: String.Encoding.utf8)
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = key.lengthOfBytes(using: String.Encoding.utf8)
        
        CCHmac(algorithm.toCCEnum(), keyStr!, keyLen, str!, strLen, result)
        
        let data = Data(bytes: UnsafePointer<UInt8>(result), count:digestLen)
        
        let base64 = data.base64EncodedString(options: NSData.Base64EncodingOptions())
        result.deinitialize()
        
        return String(base64)
    }
    
    static func Sha1AsHex(_ data:ZData) -> String {
        var result = [UInt8](repeating:0, count:Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &result)
        let data = Data(bytes:result)
        return (data as ZData).GetHexString()
    }
    
    static func MakeUuid() -> String {
        return UUID().uuidString
    }
    
    static func MD5(data:ZData) -> [UInt8] {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            CC_MD5(bytes, CC_LONG(data.count), &digest)
        }
        return digest
    }

    static func MD5ToHex(data:ZData) -> String {
        var str = ""
        for b in MD5(data:data) {
            str += String(format:"%x", b)
        }
        return str
    }
}



