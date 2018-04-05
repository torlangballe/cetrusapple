//
//  ZDefines.swift
//  Zed
//
//  Created by Tor Langballe on /5/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZObject = NSObject
typealias ZAnyObject = AnyObject
extension Dictionary where Value : Equatable {
    func oneKeyForValue(_ val : Value) -> Key? {
        for (k, v) in self {
            if v == val {
                return k
            }
        }
        return nil
    }
}

extension Dictionary where Value : Comparable {
    func keysSortedByValue() -> [Key] {
        return self.sorted{$0.1 > $1.1}.map{$0.0}
    }
}

extension Dictionary where Value : BinaryInteger {
    mutating func AdditionInsert(key:Key, add:Value) {
        if let v = self[key] {
            self[key] = v + add
        } else {
            self[key] = 1
        }
    }
}

extension Dictionary where Key : Comparable {
    func stringFromHttpParameters(escape:Bool = true, sep:String="&") -> String {
        let sorted = self.keys.sorted(by: {$0 < $1})
        let params = sorted.map { (k)->String in
            if escape {
                let percentEscapedKey = ZStrUtil.UrlQuote((k as! String))
                let percentEscapedValue = ZStrUtil.UrlQuote((self[k] as! String))
                return "\(percentEscapedKey)=\(percentEscapedValue)"
            } else {
                return "\(k)=\(String(describing: self[k]))"
            }
        }
        return params.joined(separator:sep)
    }
}

// let sortedKeys = Array(dictionary.keys).sort(<) // ["A", "D", "Z"]

extension Dictionary {
    mutating func removeIf(_ check:(_ key:Key)-> Bool) {
        if self.count > 0 {
            for (k, _) in self {
                if check(k) {
                    self.removeValue(forKey: k)
                    break
                }
            }
        }
    }
}

typealias ZRange = NSRange

extension ZRange {
    var End: Int {
        return location + length
    }
    func Contains(_ pos:Int) -> Bool {
        return NSLocationInRange(pos, self)
    }
}

extension Array {
    @discardableResult mutating func removeIf(_ check:(_ object:Element)-> Bool) -> Bool {
        var i = 0
        while i < count {
            if check(self[i]) {
                remove(at: i)
            } else {
                i += 1
            }
        }
        return false
    }
    
    mutating func shuffle () {
        for i in (0 ..< self.count).reversed() {
            let ix1 = i
            let ix2 = Int(arc4random_uniform(UInt32(i+1)))
            (self[ix1], self[ix2]) = (self[ix2], self[ix1])
        }
    }

    mutating func removeRandomElement() {
        let i = Int(arc4random_uniform(UInt32(count)))
        remove(at:i)
    }
    
    func shuffled () -> [Element] {
        var list = Array(self)
        list.shuffle()
        return list
    }

    mutating func moveItem(from:Int, to:Int) {
        var t = to
        if from < to {
            t = Swift.max(0, t - 1) // anoth max here in Array, so use Swift.max 
        }
        insert(remove(at:from), at:t)
    }
}

extension Array where Element : Equatable {
    @discardableResult mutating func addUnique(_ element:Element, atIndex:Int = -1) -> Bool { // adds if doesn't contain already.  returns true if adds
        for e in self {
            if e == element {
                return false
            }
        }
        if atIndex == -1 {
            append(element)
        } else {
            insert(element, at:atIndex)
        }
        return true
    }

    @discardableResult mutating func appendUnique(_ elements:[Element]) -> Int { // adds if doesn't contain already.  returns how many added
        var count = 0
        for e in elements {
            if addUnique(e) {
                count += 1
            }
        }
        return count
    }
    
    func subtract(_ sub:Array<Element>) -> Array<Element> {
        return self.filter{!sub.contains($0)}
    }
    
    @discardableResult mutating func removeValue(_ v:Element) -> Bool {
        if let i = index(where:{$0 == v}) {
            remove(at:i)
            return true
        }
        return false
    }
    
}

extension Array {
    func Max<T:Comparable>(get:(_ e:Element)->T) -> Element {
        return reduce(first!) { (r, e) in
            if get(r) < get(e) {
                return e
            }
            return r
        }
    }
    func Min<T:Comparable>(get:(_ e:Element)->T) -> Element {
        return reduce(first!) { (r, e) in
            if get(r) > get(e) {
                return e
            }
            return r
        }
    }
    mutating func popFirst() -> Element? {
        if count == 0 {
            return nil
        }
        let e = first!
        remove(at:0)
        return e
    }
}

extension String {
    var fullNSRange: NSRange {
        get { return NSRange(location:0, length:NSString(string:self).length) }
    }
    
    var fullRange: Range<Index> {
        let s = self.startIndex
        let e = self.endIndex
        let range = s ..< e
        return range
    }
    
    var lastCharAsString: String {
        if let c = self.last {
            return String(c)
        }
        return ""
    }

    var firstCharAsString: String {
        if let c = self.first {
            return String(c)
        }
        return ""
    }

}

extension Character
{
    func unicodeScalarCodePoint() -> UInt32
    {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        
        return scalars[scalars.startIndex].value
    }
}

func += <KeyType, ValueType> (left:inout Dictionary<KeyType, ValueType>, right:Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey:k)
    }
}
private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

func ZIsAnyObjectBool(_ a:ZAnyObject) -> Bool {
    if a is NSNumber {
        let objCType = String(cString: a.objCType)
        if (a.compare(trueNumber) == ComparisonResult.orderedSame && objCType == trueObjCType)
            || (a.compare(falseNumber) == ComparisonResult.orderedSame && objCType == falseObjCType){
            return true
        }
    }
    return false
}

func ZIsAnyObjectReal(_ a:ZAnyObject) -> Bool {
    if let f = a as? Float64 {
        if let i = a as? Int64 {
            return Int64(f) == i
        }
    }
    return false
}

@discardableResult func minimize<T: SignedNumeric & Comparable>(_ me: inout T, _ a: T) -> Bool {
    if a < me {
        me = a
        return true
    }
    return false
}

@discardableResult func maximize<T: SignedNumeric & Comparable>(_ me: inout T, _ a: T) -> Bool {
    if a > me {
        me = a
        return true
    }
    return false
}


