//
//  ZJSONNew.swift
//  PocketProbe
//
//  Created by Tor Langballe on /13/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import Foundation

typealias ZJSONData = ZData;
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
    func serialiser() -> ZJSONSerializer {
        return ZJSONSerializer()
    }
}

extension ZData {
    static func EncodeJson<T : Encodable>(serializer: JSONEncoder, item:T) -> ZData? {
        do {
            let d = try serializer.encode(item)
            return d
        } catch let error {
            ZDebug.Print("ZJSONData Encode err:", error)
            return nil
        }
    }
    
    func Decode<T:Decodable>(_ serializer: JSONEncoder) -> (T?, ZError?) {
        let decoder = JSONDecoder()
        do {
            let v = try decoder.decode(T.self, from:self)
            return (v, nil)
        } catch let error {
            ZDebug.Print("error trying to convert json to object:", error.localizedDescription)
            return (nil, error)
        }
    }
}


