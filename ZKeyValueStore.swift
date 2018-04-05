//
//  ZKeyValueStore.swift
//  Zed
//
//  Created by Tor Langballe on /30/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

struct ZKeyValueStoreCloud {
    static func store() -> NSUbiquitousKeyValueStore                            { return NSUbiquitousKeyValueStore.default }
    static func ObjectForKey(_ key:String) -> AnyObject?                        { return store().object(forKey: key) as AnyObject? }
    static func SetObject(_ anObject: AnyObject?, key:String)                   { store().set(anObject, forKey:key)}
    static func RemoveObjectForKey(_ key:String)                                { store().removeObject(forKey: key) }
    static func StringForKey(_ key:String) -> String?                           { return store().string(forKey: key) }
    static func ArrayForKey(_ key:String) -> [AnyObject]?                       { return store().array(forKey: key) as [AnyObject]? }
    static func DictionaryForKey(_ key:String) -> [String : AnyObject]?         { return store().dictionary(forKey: key) as [String : AnyObject]? }
    static func DataForKey(_ key:String) -> Data?                               { return store().data(forKey: key) }
    static func Int64ForKey(_ key:String) -> Int64                              { return store().longLong(forKey: key) }
    static func DoubleForKey(_ key:String) -> Double                            { return store().double(forKey: key) }
    static func BoolForKey(_ key:String) -> Bool                                { return store().bool(forKey: key) }
    static func SetString(_ string: String?, key:String)                        { store().set(string,  forKey:key) }
    static func SetData(_ data: Data?, key:String)                              { store().set(data,  forKey:key) }
    static func SetArray(_ anArray: [AnyObject]?, key:String)                   { store().set(anArray, forKey:key) }
    static func SetDictionary(_ aDictionary: [String : AnyObject]?, key:String) { store().set(aDictionary,  forKey:key) }
    static func SetLongLong(_ value: Int64, key:String)                         { store().set(value,  forKey:key) }
    static func SetDouble(_ value: Double, key:String)                          { store().set(value,  forKey:key) }
    static func SetBool(_ value: Bool, key:String)                              { store().set(value,  forKey:key) }
    static func Synch() -> Bool                                                 { return store().synchronize() }
}

struct ZKeyValueStore {
    static var keyPrefix = ""
    static func store() -> UserDefaults                                         { return UserDefaults.standard }
    static func ObjectForKey(_ key:String) -> AnyObject?                        { return store().object(forKey: makeKey(key)) as AnyObject? }
    static func SetObject(_ anObject: AnyObject?, key:String)                   { store().set(anObject, forKey:makeKey(key))}
    static func StringForKey(_ key:String) -> String?                           { return store().string(forKey: makeKey(key)) }
    static func ArrayForKey(_ key:String) -> [AnyObject]?                       { return store().array(forKey: makeKey(key)) as [AnyObject]? }
    static func DictionaryForKey(_ key:String) -> [String : AnyObject]?         { return store().dictionary(forKey: makeKey(key)) as [String : AnyObject]? }
    static func DataForKey(_ key:String) -> Data?                               { return store().data(forKey: makeKey(key)) }
    static func IntForKey(_ key:String) -> Int                                  { return store().integer(forKey: makeKey(key)) }
    static func DoubleForKey(_ key:String) -> Double                            { return store().double(forKey: makeKey(key)) }
    static func TimeForKey(_ key:String) -> ZTime?                              { return ObjectForKey(key) as? ZTime }

    static func BoolForKey(_ key:String, def:Bool? = nil) -> Bool {
        if def != nil && ObjectForKey(key) == nil {
            return def!
        }
        return store().bool(forKey: makeKey(key))
    }

    static func IncrementInt(_ key:String, sync:Bool = true, inc:Int = 1) -> Int {
        var val = IntForKey(key)
        val += inc
        SetInt(val, key:key, sync:sync)
        return val
    }
    static func RemoveForKey(_ key:String, sync:Bool = true) {
        store().removeObject(forKey: makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }

    static func SetString(_ string: String?, key:String, sync:Bool = true) {
        store().set(string,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetData(_ data: Data?, key:String, sync:Bool = true) {
        store().set(data,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetArray(_ anArray: [AnyObject]?, key:String, sync:Bool = true) {
        store().set(anArray, forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetDictionary(_ aDictionary: [String : AnyObject]?, key:String, sync:Bool = true) {
        store().set(aDictionary,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetInt(_ value:Int, key:String, sync:Bool = true) {
        store().set(value,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetDouble(_ value: Double, key:String, sync:Bool = true) {
        store().set(value,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetBool(_ value: Bool, key:String, sync:Bool = true) {
        store().set(value,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    static func SetTime(_ value:ZTime, key:String, sync:Bool = true) {
        store().set(value,  forKey:makeKey(key))
        if sync { ZKeyValueStore.Synch() }
    }
    @discardableResult static func Synch() -> Bool {
        return store().synchronize()
    }
    static func ForAllKeys(_ got:(_ key:String)->Void) {
        if let array = CFPreferencesCopyKeyList(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) {
            for a in (array as NSArray) {
                if var str = a as? String {
                    if !keyPrefix.isEmpty {
                        ZStrUtil.HasPrefix(str, prefix:keyPrefix, rest:&str)
                    }
                    got(str)
                }
            }
        }
    }
}

private func makeKey(_ key:String) -> String {
    if key.hasPrefix("/") {
        return key
    }
    return ZKeyValueStore.keyPrefix + key
}

