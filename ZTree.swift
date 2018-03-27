//
//  ZTree.swift
//  capsule.fm
//
//  Created by Tor Langballe on /23/3/18.
//  Copyright © 2018 Capsule.fm. All rights reserved.
//

import Foundation

class BinaryNode<T:Comparable> {
    var less:BinaryNode? = nil
    var more:BinaryNode? = nil
    var value:T? = nil
    
    var Count: Int {
        return (less?.Count ?? 0) + (more?.Count ?? 0) + 1
    }
    
    func Find(_ t:T) -> BinaryNode? {
        if value != nil {
            if value == t {
                return self
            }
            if value! > t {
                if less != nil {
                    return less!.Find(t)
                }
            } else {
                if more != nil {
                    return more!.Find(t)
                }
            }
        }
        return nil
    }
    
    func Add(_ t:T) {
        if value == nil || value! == t {
            value = t
            return
        }
        if value! > t {
            if less != nil {
                less!.Add(t)
            } else {
                less = BinaryNode()
                less!.value = t
            }
        } else {
            if more != nil {
                more!.Add(t)
            } else {
                more = BinaryNode()
                more!.value = t
            }
        }
    }
}

