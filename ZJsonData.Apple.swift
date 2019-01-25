//
//  ZJSONNew.swift
//  PocketProbe
//
//  Created by Tor Langballe on /13/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import Foundation

//typealias ZJSONData = ZData;
/*
extension ZJSONData {
    init<T : Encodable>(object:T) {
        let encoder = JSONEncoder()
        do {
            self = ZData()
            self = try encoder.encode(object)
        } catch let error {
            self = ZData()
            ZDebug.Print("ZJSONData Encode err:", error)
        }
    }

    func Decode<T:Decodable>(_ target:inout T) -> ZError? {
        let decoder = JSONDecoder()
        do {
            target = try decoder.decode(T.self, from:self)
        } catch let error {
            ZDebug.Print("error trying to convert json to object:", error.localizedDescription)
            return error
        }
        return nil
    }
}
*/

typealias ZJSONSerializer = JSONEncoder

extension Encodable  {
    static func serializer() -> JSONEncoder {
        return JSONEncoder()
    }
}

extension Decodable  {
    static func serializer() -> JSONDecoder {
        return JSONDecoder()
    }
}

extension ZData {
    static func EncodeJson<T : Encodable>(_ serializer: JSONEncoder, item:T) -> (ZData?, ZError?) {
        do {
            let d = try serializer.encode(item)
            return (d, nil)
        } catch let error {
            ZDebug.Print("ZJSONData Encode err:", error)
            return (nil, error)
        }
    }
    func Decode<T: Decodable>(_ serializer: JSONDecoder, _ t:T) -> (T?, ZError?) {
        do {
            let v = try serializer.decode(T.self, from:self)
            return (v, nil)
        } catch let error {
            ZDebug.Print("error trying to convert json to object:", error.localizedDescription)
            return (nil, error)
        }
    }
}

//extension Decodable {
//    static func Decode<T: Decodable>(_ serializer: JSONDecoder, data:ZData) -> T? {
//        do {
//            return try serializer.decode(T.self, from:data)
//        } catch let error {
//            ZDebug.Print("error trying to convert json to object:", error.localizedDescription)
//            return nil
//        }
//    }
//}
//
//
