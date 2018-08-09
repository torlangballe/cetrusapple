//
//  ZTranslations.swift
//  capsulefm
//
//  Created by Tor Langballe on /10/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//


import Foundation

let ZTSOverrideKey = "/ZOverrideTransLangCode" // make this absolute, as it's read very early before userid is used as prefix to keys
private var translations = Translations()
private var mainLoaded = false;


func ZTS(_ str:String, langCode:String = "", filePath:String = #file, args:CVarArg...) -> String {
    var trans: Translations
    if langCode == "en" {
        return ZStr.Format(str, args)
    }
    if langCode != "" {
        trans = Translations()
        trans.load(langCode)
    } else {
        if !mainLoaded {
            translations.load("")
        }
        trans = translations
    }
    let fileName = ZStr.TailUntil(filePath, sep:"/")
    var r = trans.Find(str, fileName:fileName)
    r = ZStr.Format(r, args)
    return r
}

func ZSetTranslationLangCode(_ code:String) {
    ZKeyValueStore.SetString(code, key:ZTSOverrideKey)
    mainLoaded = false
}

class Translations {
    var dict = [String:String]()
    
    func Find(_ str:String, fileName:String) -> String {
        let key = fileName + ":" + str
        if let trans = dict[key] {
            return trans
        }
        for (k, v) in dict {
            let (_, s) = ZStr.SplitInTwo(k, sep:":")
            if s != "" {                
                if s == str {
                    return v
                }
            }
        }
        return str
    }
    
    func Add(_ str:String, trans:String, fileName:String) {
        let key = fileName + ":" + str
        dict[key] = trans
    }

    func load(_ langCode:String) {
        var lang = ""
        if !langCode.isEmpty {
            lang = langCode
        } else {
            mainLoaded = true
            dict.removeAll()
            lang = ZLocale.GetDeviceLanguageCode()
            if lang == "nb" {
                lang = "no"
            }
            if let overrideLang = ZKeyValueStore.StringForKey(ZTSOverrideKey) {
                if !overrideLang.isEmpty {
                    lang = overrideLang
                }
            }
        }
        if lang == "en" || lang.isEmpty {
            return
        }
        let file = ZFolders.GetFileInFolderType(.resources, addPath:"translations/" + lang + ".pot")
        if !file.Exists() {
            ZDebug.Print("Error loading translation:", lang)
        } else {
            var english = ""
            var trans = ""
            var isTrans = false
            var fileName = ""
            let (sfile, _) = ZStr.LoadFromFile(file)
            ZStr.ForEachLine(sfile) { (str) in
                var line = ""
                var extra = ""
                let label = ZStr.HeadUntil(str, sep:" ", rest:&line)
                switch label {
                case "#:":
                    fileName = ZStr.TailUntil(ZStr.Trim(line), sep:"/")
                    
                case "msgid":
                    isTrans = false
                    getQuoted(line, dest:&english)
                    
                case "msgstr":
                    isTrans = true
                    getQuoted(line, dest:&trans)
                    
                case "":
                    if !trans.isEmpty {
                        translations.Add(english, trans:trans, fileName:fileName)
                    }
                    english = ""
                    trans = ""
                    
                case "#":
                    break
                    
                default:
                    if getQuoted(str, dest:&extra) { // use str and not line here
                        if isTrans {
                            trans += extra
                        } else {
                            english += extra
                        }
                    }
                }
                return true
            }
        }
    }
}

@discardableResult private func getQuoted(_ str:String, dest: inout String) -> Bool {
    var vstr = ZStr.Trim(str, chars:" \t\r\n")
    if !vstr.isEmpty {
        if vstr.firstCharAsString == "\"" && vstr.lastCharAsString == "\"" {
            vstr = ZStr.Body(vstr, pos:1, size:vstr.count - 2)
            dest += ZStr.Unescape(vstr)
            return true
        }
    }
    return false
}

