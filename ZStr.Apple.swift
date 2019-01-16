//
//  ZStr.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

// #package com.github.torlangballe.cetrusandroid

import Foundation

typealias ZStringCompareOptions = NSString.CompareOptions

struct ZStr {
    static func Utf8(_ str:String) -> String.UTF8View {
        return str.utf8
    }

    static func Format(_ format:String, _ args:CVarArg...) -> String {
        let vformat = format.replacingOccurrences(of:"%S", with:"%@") // need something better than this replacement %%S etc
        return NSString(format:vformat, arguments: getVaList(args)) as String
    }
    
    @discardableResult static func SaveToFile(_ str:String, file:ZFileUrl) -> ZError? {
        do {
            try str.write(to: file.url! as URL, atomically:true, encoding:String.Encoding.utf8)
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    static func LoadFromFile(_ file:ZFileUrl) -> (String, ZError?) {
        var str = ""
        do {
            str = try NSString(contentsOf:file.url! as URL, encoding: String.Encoding.utf8.rawValue) as String
        } catch let error as NSError {
            return ("", error)
        }
        return (str, nil)
    }
    
    static func FindFirstOfChars(_ str:String, charset:String) -> Int {
        let set = CharacterSet(charactersIn:charset)
        if let range = str.rangeOfCharacter(from: set, options:.literal, range:str.fullRange) {
            return str.distance(from: str.startIndex, to: range.lowerBound)
        }
        return -1
    }

    static func FindLastOfChars(_ str:String, charset:String) -> Int {
        let set = CharacterSet(charactersIn:charset)
        let opts = NSString.CompareOptions(rawValue:NSString.CompareOptions.literal.rawValue | NSString.CompareOptions.backwards.rawValue)
        if let foundRange = str.rangeOfCharacter(from: set, options:opts, range:str.fullRange) {
            return str.distance(from: str.startIndex, to: foundRange.lowerBound)
        }
        return -1
    }

    static func Join(_ strs:[String], sep:String) -> String {
        return NSArray(array: strs).componentsJoined(by: sep)
    }

    static func Split(_ str:String, sep:String) -> [String] {
        if str.isEmpty {
            return []
        }
        return str.components(separatedBy: sep)
    }
    
    static func SplitByChars(_ str:String, chars:String) -> [String] {
        return str.components(separatedBy: CharacterSet(charactersIn:chars))
    }
    
    static func SplitN(_ str:String, sep:String, n:Int) -> [String] {
        var comps = ZStr.Split(str, sep:sep)
        if comps.count <= n {
            return comps
        }
        let joined = ZStr.Join(Array(comps[n ..< comps.endIndex]), sep:sep)
        let out = Array(comps[0 ..< n]) + [joined]
        return out
    }
    
    static func SplitInTwo(_ str:String, sep:String) -> (String, String) {
        let parts = SplitN(str, sep:sep, n:2)
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        if parts.count == 1 {
            return (parts[0], "")
        }
        return ("", "")
    }
    
    static func CountLines(_ str:String) -> Int {
        var count = 0
        str.enumerateLines { (line, quit) in count += 1 }
        return count
    }
    
    static func Head(_ str: String, chars:Int = 1) -> String {
        var c = str.count
        if chars < 1 {
            return ""
        }
        c = min(c, chars)
        let pos = str.index(str.startIndex, offsetBy: c)
//        let head = str.substring(to: index)
//        return head

        let head = str[str.startIndex ..< pos]
        return String(head)
}
    
    static func Tail(_ str: String, chars:Int = 1) -> String {
        if chars >= str.count {
            return str
        }
        let index = str.index(str.endIndex, offsetBy: -chars)
        let range = index ..< str.endIndex
        let tail = str[range]
        
        return String(tail)
    }

    static func Body(_ str:String, pos:Int, size:Int = -1) -> String {
        if size == 0 {
            return ""
        }
        let c = str.count
        if str.isEmpty || pos >= c {
            return ""
        }
        var vsize = size
        let vpos = min(c, max(0, pos))
        if vsize == -1 {
            vsize = c - vpos
        } else {
            vsize = min(vsize, c - vpos)
        }
        let s = str.index(str.startIndex, offsetBy: pos)
        let e = str.index(s, offsetBy: vsize)
        let range = s ..< e
        let body = str[range]
        return String(body)
    }

    @discardableResult static func HeadUntil(_ str: String, sep:String, rest:inout String, options: ZStringCompareOptions = .literal) -> String {
        let s = ZStr.HeadUntil(str, sep:sep, options:options)
        rest = ZStr.Body(str, pos:(s + sep).count)
        return s
    }

    static func HeadUntil(_ str: String, sep:String, options: ZStringCompareOptions = .literal) -> String {
        let foundRange = str.range(of: sep, options:options)// range searchRange: Range<Index>? = default, locale: NSLocale? = default) -> Range<Index>?
        if foundRange != nil {
            let range = str.startIndex ..< (foundRange?.lowerBound)!
            let head = str[range]
            return String(head)
        }
        return str
    }

    static func TailUntil(_ str: String, sep:String, options: ZStringCompareOptions = .literal) -> String {
        if let range = rangeOfWordAtEnd(str, sep:sep, options:options) {
            let tail = str[range]
            return String(tail)
        }
        return str
    }

    static func TailUntilWithRest(_ str: String, sep:String, options: ZStringCompareOptions = .literal) -> (String, String) {
        if let range = rangeOfWordAtEnd(str, sep:sep, options:options) {
            let tail = str[range]
            return (String(tail), Head(str, chars:range.lowerBound.encodedOffset))
        }
        return (str, "")
    }
    
    static func PopTailWord(_ str:inout String, sep:String = " ", options:ZStringCompareOptions = .literal) -> String {
        if let range = rangeOfWordAtEnd(str, sep:sep, options:options) {
            let tail = str[range]
            str.removeSubrange(range)
            str = ZStr.Trim(str)
            return String(tail)
        }
        return str
    }

    static func PopHeadWord(_ str:inout String, sep:String = " ", options:ZStringCompareOptions = .literal) -> String {
        if let range = rangeOfWordAtStart(str, sep:sep, options:options) {
            let head = str[range]
            str.removeSubrange(range)
            str = ZStr.Trim(str)
            return String(head)
        }
        return str
    }
    
    @discardableResult static func HasPrefix(_ str:String, prefix:String, rest:inout String) -> Bool {
        if str.hasPrefix(prefix) {
            rest = ZStr.Body(str, pos:prefix.count)
            return true
        }
        return false
    }
    
    @discardableResult static func HasSuffix(_ str:String, suffix:String, rest:inout String) -> Bool {
        if str.hasSuffix(suffix) {
            rest = ZStr.Head(str, chars:str.count - suffix.count)
            return true
        }
        return false
    }

    static func TruncatedEnd(_ str:String, chars:Int = 1) -> String {
        return String(str.dropLast(chars))
    }
    
    static func TruncatedStart(_ str:String, chars:Int = 1) -> String {
        return String(str.dropFirst(chars))
    }
    
    static func TruncateMiddle(_ str:String, maxChars:Int, separator:String) -> String { // sss...eee of longer string
        if str.count > maxChars {
            return ZStr.Head(str, chars:maxChars / 2) + separator + ZStr.Tail(str, chars:maxChars / 2)
        }
        return str
    }
    
    static func ConcatNonEmpty(sep: String = " ", items:[String]) -> String {
        var str = ""
        var first = true
        for item in items {
            if !item.isEmpty {
                if !first {
                    str += sep
                }
                str += String(item)
                first = false
            }
        }
        return str
    }

    static func Compare(a:String, b:String, reverse:Bool = false, caseless:Bool = true, removeThe:Bool = false, sortAlphaFirst:Bool = false) -> Bool {
        var order = false
        var va = a
        var vb = b
        if removeThe {
            if va.lowercased().hasPrefix("the ") {
                va = ZStr.Body(va, pos:4)
            }
            if vb.lowercased().hasPrefix("the ") {
                vb = ZStr.Body(vb, pos:4)
            }
        }
        if sortAlphaFirst && !va.isEmpty && !vb.isEmpty{
            let alpha = CharacterSet.alphanumerics
            let ac = alpha.contains(UnicodeScalar(va.utf16.first!)!)
            let bc = alpha.contains(UnicodeScalar(vb.utf16.first!)!)
            if ac && !bc {
                return true
            }
            if !ac && bc {
                return false
            }
        }
        if caseless {
            order = va.localizedCaseInsensitiveCompare(vb) == ComparisonResult.orderedAscending
        } else {
            order = va.localizedCompare(vb) == ComparisonResult.orderedAscending
        }
        return reverse ? !order : order
    }

    static func SortArray(_ strings:inout [String], reverse:Bool = false, caseless:Bool = true, removeThe:Bool = false) {
        strings.sort {
            return Compare(a:$0, b:$1, reverse:reverse, caseless:caseless, removeThe:removeThe)
        }
    }

    static func Sorted(_ strings:[String], reverse:Bool = false, caseless:Bool = true, removeThe:Bool = false) -> [String] {
        return strings.sorted {
            return Compare(a:$0, b:$1, reverse:reverse, caseless:caseless, removeThe:removeThe)
        }
    }

    static func ReplaceWhiteSpaces(_ str:String, to:String) -> String {
        var out = [Character]()
        let chars = Array(to)
        var white = false
        for c in str {
            switch c {
                case "\n", "\r", "\t":
                    white = true
                
                default:
                    if(white) {
                        out += chars
                        white = false
                    }
                    out.append(c)
            }
        }
        if white {
            out += chars
        }
        return String(out)
    }
    
    static func Replace(_ str:String, find:String, with:String, caseless:Bool = false) -> String {
        let options:ZStringCompareOptions = caseless ? .literal : .caseInsensitive
        return str.replacingOccurrences(of: find, with:with, options:options, range:str.fullRange)
    }
    
    static func Evaluate(_ str:String, args:[String:AnyObject] = [:]) -> Double? {
        var replaced = str
        if !args.isEmpty {
            for (k, v) in args {
                replaced = ZStr.Replace(replaced, find:k, with:"\(v)")
            }
        }
        let exp = NSExpression(format:replaced)
        if let result = exp.expressionValue(with: nil, context: nil) as? Double {
            return result
        }
        return nil
    }
    
    static func Trim(_ str:String, chars:String = " ") -> String {
        let set = CharacterSet(charactersIn:chars)
        return str.trimmingCharacters(in: set)
    }
    
    static func CountInstances(_ instance:String, str:String) -> Int {
        return str.components(separatedBy: instance).count - 1
    }
    
    static func FilterToAlphaNumeric(_ str:String) -> String {
        let alphaNumerics = CharacterSet.alphanumerics
        let filteredCharacters = str.filter {
            return String($0).rangeOfCharacter(from: alphaNumerics) != nil
        }
        return String(filteredCharacters)
    }

    static func FilterToNumeric(_ str:String) -> String {
        let filteredCharacters = str.filter {
            return String($0).rangeOfCharacter(from:CharacterSet.decimalDigits) != nil
        }
        return String(filteredCharacters)
    }
    
    static func CamelCase(_ str:String) -> String {
        return str.capitalized.replacingOccurrences(of: " ", with:"")
    }
    
    static func IsUppercase(_ c:Character) -> Bool {
        let s = String(c)
        return (s == s.uppercased())
    }
    
    static func SplitCamelCase(_ str:String) -> [String] {
        var out = [String]()
        var word = ""
        for c in str {
            if ZStr.IsUppercase(c) {
                if !word.isEmpty {
                    out.append(word)
                    word = ""
                }
            }
            word += String(c).lowercased()
        }
        if !word.isEmpty {
            out.append(word)
        }
        return out
    }
    
    static func HashToU64(_ str:String) -> UInt64 {
        var result = UInt64 (5381)
        let buf = [UInt8](str.utf8)
        for b in buf {
            result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
        }
        return result
    }

    static func MakeHashTagWord(_ str:String) -> String {
        let split = ZStr.SplitByChars(str, chars:" .-,/()_")
        var words = [String]()
        for s in split {
            words += ZStr.SplitCamelCase(ZStr.FilterToAlphaNumeric(s))
        }
        let flat = words.reduce("") { $0 + $1.capitalized }
        return flat
    }
    
    static func Unescape(_ str:String) -> String {
        var vstr = str.replacingOccurrences(of: "\\n", with:"\n")
        vstr = vstr.replacingOccurrences(of: "\\r", with:"\r")
        vstr = vstr.replacingOccurrences(of: "\\t", with:"\t")
        vstr = vstr.replacingOccurrences(of: "\\\"", with:"\"")
        vstr = vstr.replacingOccurrences(of: "\\'", with:"'")
        vstr = vstr.replacingOccurrences(of: "\\\\", with:"\\")

        return vstr
    }
    
    static func ForEachLine(_ str:String, forEach:(_ sline:String)->Bool) {
        let all = str.components(separatedBy: CharacterSet.newlines)
        for s in all {
            if !forEach(s) {
                break
            }
        }
    }
    static func Base64Encode(_ str:String) -> String {
        let base64 = ZData(utfString:str)!.base64EncodedString(options: NSData.Base64EncodingOptions())        
        return base64
    }
    
    static func UrlEncode(_ str:String) -> String? {
        let chars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~?")
        if let encoded = str.addingPercentEncoding(withAllowedCharacters:chars) {
            return encoded
        }
        return nil
    }

    static func UrlDecode(_ str:String) -> String? {
        return str.removingPercentEncoding
    }
    
    static func StrMatchsWildcard(_ str:String, wild:String) -> Bool {
        let pred = NSPredicate(format:"self LIKE %@", wild)
        let matches = pred.evaluate(with:str)
        return matches
    }
    
    static func CopyToCCharArray(carray:UnsafeMutablePointer<Int8>, str:String) { // this requires pointer to FIRST tuple using .0
        let c = str.utf8.count + 1
        _ = strlcpy(carray, str, c) // str is coerced to c-string amazingly enough
    }

    static func StrFromCCharArray(_ carray:UnsafeMutablePointer<Int8>?) -> String { // this requires pointer to FIRST tuple using .0 if it's char[256] etc
        if carray == nil {
            return ""
        }
        return String(cString:carray!)
    }

    static func CopyStrToAllocedCStr(_ str:String, len:Int) -> UnsafeMutablePointer<Int8> {
        let pointer = UnsafeMutablePointer<Int8>.allocate(capacity:len)
        strcpy(pointer, str)
        return pointer
    }
    
    static func NiceDouble(_ d:Double, maxSig:Int = 8, separator:String = ",") -> String {
        let str = ZStr.Format("%lf", d)
        var sfract = ZStr.TailUntil(str, sep: ".")
        sfract = ZStr.Head(sfract, chars: maxSig)
        var n = Int64(d)
        var sint = ""
        while true {
            if n / 1000 > 0 {                
                sint = ZStr.Format("%03ld", n % 1000) + sint
            } else {
                sint = "\(n % 1000)" + sint
            }
            n /= 1000
            if n == Int64(0) {
                break
            }
            sint = separator + sint
        }
        if !sfract.isEmpty {
            sfract = "." + sfract
        }
        return sint + sfract
    }
    
    static func ToDouble(str:String, def:Double = -1.0) -> Double {
        if let d = Double(str) {
            return d
        }
        return def
    }
    

    static func GetStemAndExtension(fileName:String) -> (String, String) {
        return ZStr.TailUntilWithRest(fileName, sep:".")
    }
    
    static func SplitLines(str:String, skipEmpty:Bool = true) -> [String] {
        var lines = [String]()
        str.enumerateLines { line, stop in
            if !skipEmpty || !line.isEmpty {
                lines.append(line)
            }
        }
        return lines
    }
    
    static func Base64CharToNumber(_ char:Int) -> Int {
        let iA = Int(UnicodeScalar("A")!.value)
        let iZ = Int(UnicodeScalar("Z")!.value)
        let ia = Int(UnicodeScalar("a")!.value)
        let iz = Int(UnicodeScalar("z")!.value)
        let i0 = Int(UnicodeScalar("0")!.value)
        let i9 = Int(UnicodeScalar("9")!.value)
        let iPlus = Int(UnicodeScalar("+")!.value)
        let iSlash = Int(UnicodeScalar("/")!.value)
        
        switch char {
        case iA ... iZ:
            return char - iA
            
        case ia ... iz:
            return char - ia + 26
        
        case i0 ... i9:
            return char - i0 + 26 + 26
        
        case iPlus:
            return 62
        
        case iSlash:
            return 63

        default:
            return -1
        }
    }

    static func NumberToBase64String(_ num:Int) -> String {
        if let scalar = NumberToBase64Char(num) {
            return String(Character(UnicodeScalar(scalar)!))
        }
        return ""
    }

    static func NumberToBase64Char(_ num:Int) -> Int? {
        let iA = Int(UnicodeScalar("A")!.value)
        let ia = Int(UnicodeScalar("a")!.value)
        let i0 = Int(UnicodeScalar("0")!.value)
        let iPlus = Int(UnicodeScalar("+")!.value)
        let iSlash = Int(UnicodeScalar("/")!.value)
        
        switch num {
        case 0 ..< 26:
            return iA + num
            
        case 26 ..< 52:
            return ia + num - 26
            
        case 52 ..< 62:
            return i0 + num - 26 - 26

        case 62:
            return iPlus
            
        case 63:
            return iSlash
            
        default:
            return nil
        }
    }

}

private func rangeOfWordAtEnd(_ str: String, sep:String, options:ZStringCompareOptions) -> Range<String.Index>? {
    let voptions = options.union(ZStringCompareOptions.backwards)
    if let foundRange = str.range(of: sep, options:voptions) {
        let range = foundRange.upperBound ..< str.endIndex
        return range
    }
    return nil
}

private func rangeOfWordAtStart(_ str: String, sep:String, options:ZStringCompareOptions) -> Range<String.Index>? {
    if let foundRange = str.range(of:sep, options:options) {
        let range = str.startIndex ..< foundRange.lowerBound
        return range
    }
    return nil
}
