//
//  ZStrUtil.swift
//  Zed
//
//  Created by Tor Langballe on /23/9/14.
//  Copyright (c) 2014 Capsule.fm. All rights reserved.
//

import Foundation

// http://ericasadun.com/2015/05/06/swift-indices/ -- shows how everything below sucks!

typealias ZStringCompareOptions = NSString.CompareOptions

class ZStrUtil {
    @discardableResult class func SaveToFile(_ str:String, file:ZFileUrl) -> Error? {
        do {
            try str.write(to: file.url! as URL, atomically:true, encoding:String.Encoding.utf8)
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    class func LoadFromFile(_ file:ZFileUrl) -> (String, Error?) {
        var str = ""
        do {
            str = try NSString(contentsOf:file.url! as URL, encoding: String.Encoding.utf8.rawValue) as String
        } catch let error as NSError {
            return ("", error)
        }
        return (str, nil)
    }
    
    class func FindFirstOfChars(_ str:String, charset:String) -> Int {
        let set = CharacterSet(charactersIn:charset)
        if let range = str.rangeOfCharacter(from: set, options:.literal, range:str.fullRange) {
            return str.distance(from: str.startIndex, to: range.lowerBound)
        }
        return -1
    }

    class func FindLastOfChars(_ str:String, charset:String) -> Int {
        let set = CharacterSet(charactersIn:charset)
        let opts = NSString.CompareOptions(rawValue:NSString.CompareOptions.literal.rawValue | NSString.CompareOptions.backwards.rawValue)
        if let foundRange = str.rangeOfCharacter(from: set, options:opts, range:str.fullRange) {
            return str.distance(from: str.startIndex, to: foundRange.lowerBound)
        }
        return -1
    }

    class func Join(_ strs:[String], sep:String) -> String {
        return NSArray(array: strs).componentsJoined(by: sep)
    }

    class func Split(_ str:String, sep:String) -> [String] {
        if str.isEmpty {
            return []
        }
        return str.components(separatedBy: sep)
    }
    
    class func SplitByChars(_ str:String, chars:String) -> [String] {
        return str.components(separatedBy: CharacterSet(charactersIn:chars))
    }
    
    class func SplitN(_ str:String, sep:String, n:Int) -> [String] {
        var out = [String]()
        var comps = ZStrUtil.Split(str, sep:sep)
        if comps.count <= n {
            return comps
        }
        for _ in 1 ..< n {
            if comps.count > 0 {
                out.append(comps.first!)
                comps.remove(at: 0)
            }
        }
        out.append(ZStrUtil.Join(comps, sep:sep))
        return out
    }
    
    @discardableResult class func SplitInTwo(_ str:String, sep:String, first:inout String, rest:inout String) -> Bool {
        let parts = SplitN(str, sep:sep, n:2)
        if parts.count == 2 {
            first = parts[0]
            rest = parts[1]
            return true
        }
        return false
    }
    
    class func CountLines(_ str:String) -> Int {
        var count = 0
        str.enumerateLines { (line, quit) in count += 1 }
        return count
    }
    
    @discardableResult class func SplitToArgs(_ str:String, sep:String, a:inout String, b:inout String) -> Bool {
        let parts = ZStrUtil.Split(str, sep:sep)
        if parts.count == 2 {
            a = parts[0]
            b = parts[1]
            return true
        }
        return false
    }
    
    class func Head(_ str: String, chars:Int) -> String {
        var c = str.count
        if chars < 1 {
            return ""
        }
        minimize(&c, chars)
        let pos = str.index(str.startIndex, offsetBy: c)
//        let head = str.substring(to: index)
//        return head

        let head = str[str.startIndex ..< pos]
        return String(head)
}
    
    class func Tail(_ str: String, chars:Int) -> String {
        if chars >= str.count {
            return str
        }
        let index = str.index(str.endIndex, offsetBy: -chars)
        let range = index ..< str.endIndex
        let tail = str[range]
        
        return String(tail)
    }

    class func Body(_ str:String, pos:Int, size:Int = -1) -> String {
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
            minimize(&vsize, c - vpos)
        }
        let s = str.index(str.startIndex, offsetBy: pos)
        let e = str.index(s, offsetBy: vsize)
        let range = s ..< e
        let body = str[range]
        return String(body)
    }

    @discardableResult class func HeadUntil(_ str: String, sep:String, rest:inout String, options: ZStringCompareOptions = .literal) -> String {
        let s = ZStrUtil.HeadUntil(str, sep:sep, options:options)
        rest = ZStrUtil.Body(str, pos:(s + sep).count)
        return s
    }

    class func HeadUntil(_ str: String, sep:String, options: ZStringCompareOptions = .literal) -> String {
        let foundRange = str.range(of: sep, options:options)// range searchRange: Range<Index>? = default, locale: NSLocale? = default) -> Range<Index>?
        if foundRange != nil {
            let range = str.startIndex ..< (foundRange?.lowerBound)!
            let head = str[range]
            return String(head)
        }
        return str
    }

    class func TailUntil(_ str: String, sep:String, options: ZStringCompareOptions = .literal) -> String {
        let voptions = options.union(ZStringCompareOptions.backwards)
        if let foundRange = str.range(of: sep, options:voptions) {// range searchRange: Range<Index>? = default, locale: NSLocale? = default) -> Range<Index>?
            let range = foundRange.upperBound ..< str.endIndex
            let tail = str[range]
            return String(tail)
        }
        return str
    }
    
    class func UrlQuote(_ str: String) -> String {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-._~")
        return str.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)!
    }

    class func UrlQueryQuote(_ str: String) -> String {
        return str.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed) ?? ""
    }
    
    @discardableResult class func HasPrefix(_ str:String, prefix:String, rest:inout String) -> Bool {
        if str.hasPrefix(prefix) {
            rest = ZStrUtil.Body(str, pos:prefix.count)
            return true
        }
        return false
    }
    
    @discardableResult class func HasSuffix(_ str:String, suffix:String, rest:inout String) -> Bool {
        if str.hasSuffix(suffix) {
            rest = ZStrUtil.Head(str, chars:str.count - suffix.count)
            return true
        }
        return false
    }

    class func TruncatedEnd(_ str:String, chars:Int) -> String {
        var c = str.count
        c = c - chars
        if c < 1 {
            return ""
        }
        return Head(str, chars:c)
    }
    
    class func TruncateMiddle(_ str:String, maxChars:Int, separator:String) -> String { // sss...eee of longer string
        if str.count > maxChars {
            return ZStrUtil.Head(str, chars:maxChars / 2) + separator + ZStrUtil.Tail(str, chars:maxChars / 2)
        }
        return str
    }
    
    class func ConcatNonEmpty(separator: String = " ", items: String...) -> String {
        var str = ""
        var first = true
        for item in items {
            if !item.isEmpty {
                if !first {
                    str += separator
                }
                str += String(item)
                first = false
            }
        }
        return str
    }

    class func Compare(a:String, b:String, reverse:Bool = false, caseless:Bool = true, removeThe:Bool = false, sortAlphaFirst:Bool = false) -> Bool {
        var order = false
        var va = a
        var vb = b
        if removeThe {
            if va.lowercased().hasPrefix("the ") {
                va = ZStrUtil.Body(va, pos:4)
            }
            if vb.lowercased().hasPrefix("the ") {
                vb = ZStrUtil.Body(vb, pos:4)
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

    class func SortArray(_ strings:inout [String], reverse:Bool = false, caseless:Bool = true, removeThe:Bool = false) {
        strings.sort {
            return Compare(a:$0, b:$1, reverse:reverse, caseless:caseless, removeThe:removeThe)
        }
    }

    class func Sorted(_ strings:[String], reverse:Bool = false, caseless:Bool = true, removeThe:Bool = false) -> [String] {
        return strings.sorted {
            return Compare(a:$0, b:$1, reverse:reverse, caseless:caseless, removeThe:removeThe)
        }
    }

    class func ReplaceWhiteSpacesWithSpace(_ str:String) -> String {
        var out = [Character]()
        var white = false
        for c in str {
            switch c {
                case "\n", "\r", "\t":
                    white = true
                
                default:
                    if(white) {
                        out.append(" ")
                        white = false
                    }
                    out.append(c)
            }
        }
        if white {
            out.append(" ")
        }
        return String(out)
    }
    
    class func Replace(_ str:String, find:String, with:String, options:ZStringCompareOptions = .literal) -> String {
        return str.replacingOccurrences(of: find, with:with, options:options, range:str.fullRange)
    }
    
    class func Evaluate(_ str:String, args:[String:AnyObject] = [:]) -> Double? {
        var replaced = str
        if !args.isEmpty {
            for (k, v) in args {
                replaced = ZStrUtil.Replace(replaced, find:k, with:"\(v)")
            }
        }
        let exp = NSExpression(format:replaced)
        if let result = exp.expressionValue(with: nil, context: nil) as? Double {
            return result
        }
        return nil
    }
    
    class func Trim(_ str:String, chars:String = " ") -> String {
        let set = CharacterSet(charactersIn:chars)
        return str.trimmingCharacters(in: set)
    }
    
    class func CountInstances(_ instance:String, str:String) -> Int {
        return str.components(separatedBy: instance).count - 1 // return's [""] for empty string, which will be 0, so good
    }
    
    class func FilterToAlphaNumeric(_ str:String) -> String {
        let alphaNumerics = CharacterSet.alphanumerics
        let filteredCharacters = str.filter {
            return String($0).rangeOfCharacter(from: alphaNumerics) != nil
        }
        return String(filteredCharacters)
    }

    class func FilterToNumeric(_ str:String) -> String {
        let filteredCharacters = str.filter {
            return String($0).rangeOfCharacter(from:CharacterSet.decimalDigits) != nil
        }
        return String(filteredCharacters)
    }
    
    class func CamelCase(_ str:String) -> String {
        return str.capitalized.replacingOccurrences(of: " ", with:"")
    }
    
    class func IsUppercase(_ c:Character) -> Bool {
        let s = String(c)
        return (s == s.uppercased())
    }
    
    class func SplitCamelCase(_ str:String) -> [String] {
        var out = [String]()
        var word = ""
        for c in str {
            if ZStrUtil.IsUppercase(c) {
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
    
    class func HashToU64(_ str:String) -> UInt64 {
        var result = UInt64 (5381)
        let buf = [UInt8](str.utf8)
        for b in buf {
            result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
        }
        return result
    }

    class func MakeHashTagWord(_ str:String) -> String {
        let split = ZStrUtil.SplitByChars(str, chars:" .-,/()_")
        var words = [String]()
        for s in split {
            words += ZStrUtil.SplitCamelCase(ZStrUtil.FilterToAlphaNumeric(s))
        }
        let flat = words.reduce("") { $0 + $1.capitalized }
        return flat
    }
    
    class func Unescape(_ str:String) -> String {
        var vstr = str.replacingOccurrences(of: "\\n", with:"\n")
        vstr = vstr.replacingOccurrences(of: "\\r", with:"\r")
        vstr = vstr.replacingOccurrences(of: "\\t", with:"\t")
        vstr = vstr.replacingOccurrences(of: "\\\"", with:"\"")
        vstr = vstr.replacingOccurrences(of: "\\'", with:"'")
        vstr = vstr.replacingOccurrences(of: "\\\\", with:"\\")

        return vstr
    }
    
    class func ForEachLine(_ str:String, line:(_ sline:String)->Bool) {
        let all = str.components(separatedBy: CharacterSet.newlines)
        for s in all {
            if !line(s) {
                break
            }
        }
    }
    class func Base64Encode(_ str:String) -> String {
        let base64 = ZData(utfString:str)!.base64EncodedString(options: NSData.Base64EncodingOptions())        
        return base64
    }
    
    class func UrlEncode(_ str:String) -> String? {
        let chars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~?")
        if let encoded = str.addingPercentEncoding(withAllowedCharacters:chars) {
            return encoded
        }
        return nil
    }

    class func UrlDecode(_ str:String) -> String? {
        return str.removingPercentEncoding
    }
    
    class func StrMatchsWildcard(_ str:String, wild:String) -> Bool {
        let pred = NSPredicate(format:"self LIKE %@", wild)
        let matches = pred.evaluate(with:str)
        return matches
    }
    
    class func CopyToCCharArray(carray:UnsafeMutablePointer<Int8>, str:String) { // this requires pointer to FIRST tuple using .0
        let c = str.utf8.count + 1
        _ = strlcpy(carray, str, c) // str is coerced to c-string amazingly enough
    }

    class func StrFromCCharArray(_ carray:UnsafeMutablePointer<Int8>?) -> String { // this requires pointer to FIRST tuple using .0 if it's char[256] etc
        if carray == nil {
            return ""
        }
        return String(cString:carray!)
    }

    class func CopyStrToAllocedCStr(_ str:String, len:Int) -> UnsafeMutablePointer<Int8> {
        let pointer = UnsafeMutablePointer<Int8>.allocate(capacity:len)
        strcpy(pointer, str)
        return pointer
    }
    
    class func NiceDouble(_ d:Double, maxSig:Int = 8) -> String {
        let format = "%.\(maxSig)lf"
        var str = String(format:format, d)
        if str.contains(".") {
            while true {
                switch str.lastCharAsString {
                case "0":
                    str.removeLast()
                case ".":
                    str.removeLast()
                    return str
                default:
                    return str
                }
            }
        }
        return str
    }
    
    class func SplitLines(str:String, skipEmpty:Bool = true) -> [String] {
        var lines = [String]()
        str.enumerateLines { line, stop in
            if !skipEmpty || !line.isEmpty {
                lines.append(line)
            }
        }
        return lines
    }
    
    class func Base64CharToNumber(_ char:Int) -> Int {
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

    class func NumberToBase64String(_ num:Int) -> String {
        if let scalar = NumberToBase64Char(num) {
            return String(Character(UnicodeScalar(scalar)!))
        }
        return ""
    }

    class func NumberToBase64Char(_ num:Int) -> Int? {
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

