//
//  ZLinguistics.swift
//  capsulefm
//
//  Created by Tor Langballe on /16/8/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation

typealias ZLinguisticTaggerOptions = NSLinguisticTagger.Options

class ZLinguisticTagger : NSLinguisticTagger {
    init(schemes:[NSLinguisticTagScheme], options:ZLinguisticTaggerOptions = ZLinguisticTaggerOptions()) {
        super.init(tagSchemes:schemes, options:Int(options.rawValue))
    }

    func ParseText(_ text:String, scheme:String, options:ZLinguisticTaggerOptions = ZLinguisticTaggerOptions(), got:@escaping (_ range:ZRange, _ langCode:String)->Void) {
        string = text
        self.enumerateTags(in: text.fullNSRange, scheme:NSLinguisticTagScheme(rawValue: scheme), options:options) { (tag, tokenRange, sentenceRange, stop) in
            got(tokenRange, tag?.rawValue ?? "")
        }
    }
    
    func GetLanguageCodesOfText(_ text:String) -> [String] {
        var langs = [String:Int]()
        ParseText(text, scheme:NSLinguisticTagScheme.language.rawValue) { (range, langCode) in
            if !langCode.isEmpty && langCode != "und" {
                langs[langCode]? += 1
            }
        }
        return langs.keysSortedByValue()
    }
}

class ZLanguageTagger : ZLinguisticTagger {
    init(options:ZLinguisticTaggerOptions = ZLinguisticTaggerOptions()) {
        super.init(schemes:[NSLinguisticTagScheme.language], options:options)
    }
}


