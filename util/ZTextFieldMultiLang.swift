//
//  ZTextLangField.swift
//  capsulefm
//
//  Created by Tor Langballe on /2/8/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation

class ZTextFieldMultiLang : ZStackView, ZTextEditDelegate {
    let textView: ZTextView
    var leftButton = ZImageView(namedImage:"arrow.left.small.png")
    var rightButton = ZImageView(namedImage:"arrow.right.small.png")
    let flagButton = ZImageView(maxSize:ZSize(36, 24))
    var deleteButton = ZImageView(namedImage:"cross.small.png")
    var addButton = ZImageView(namedImage:"add.small.png")
    let h1 = ZHStackView(space:10)
    var possibleLangs = [String]()
    var currentLang:String
    var langs: [String]
    fileprivate var strings:[String:String]
    
    var Strings : [String:String] {
        updateStrings()
        return strings
    }
    
    init(strings:[String:String], currentLang:String, possibleLangs: [String]) {
        self.strings = strings
        self.currentLang = currentLang
        self.possibleLangs = possibleLangs
        langs = strings.keys.sorted(by: <)
        textView = ZTextView(text:strings[currentLang] ?? "")
        super.init()

        vertical = true
        textView.SetTarget(self)

        Add(textView, align:.Top | .Left | .HorExpand | .NonProp, marg:ZSize(6, 4))
   
        h1.Add(addButton, align:.Right | .Bottom)
        addButton.HandlePressedInPosFunc = { [weak self] (pos) in
            let newLangs = self!.possibleLangs.subtract(self!.langs)
            self!.getNewLang(newLangs) { (key, val) in
                if key != nil {
                    self!.updateStrings()
                    self!.currentLang = key!
                    self!.langs.append(key!)
                    self!.updateButtons()
                    self!.textView.text = ""
                }
            }
        }

        h1.Add(rightButton, align:.Right | .Bottom)
        rightButton.HandlePressedInPosFunc = { [weak self] (pos) in
            if let i = self!.langs.index(of: currentLang) {
                self?.updateStrings()
                self!.currentLang = self!.langs[i+1]
                self!.textView.text = self!.strings[currentLang]
                self?.updateButtons()
            }
        }
        h1.Add(flagButton, align:.Right | .Bottom)
        
        h1.Add(leftButton, align:.Right | .Bottom)
        leftButton.HandlePressedInPosFunc = { [weak self] (pos) in
            if let i = self!.langs.index(of: self!.currentLang) {
                self!.updateStrings()
                self!.currentLang = self!.langs[i-1]
                self!.textView.text = self!.strings[currentLang]
                self!.updateButtons()
            }
        }
        h1.Add(deleteButton, align:.Left | .Bottom)
        deleteButton.HandlePressedInPosFunc = { [weak self] (pos) in
            self!.strings.removeValue(forKey: self!.currentLang)
            self!.langs.removeIf {$0 == self!.currentLang }
            self!.currentLang = self!.langs[0]
            self!.textView.text = self!.strings[currentLang]
            self!.updateButtons()
        }
        Add(h1, align:.Right | .Bottom | .HorExpand | .NonProp, marg:ZSize(4, 4))
        
        updateButtons()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    fileprivate func getNewLang(_ from:[String], got:@escaping (_ key:String?, _ val:AnyObject?)->Void) {
        var dict = [String:String]()
        for f in from {
            dict[f] = f
        }
        var t = ZTextDraw()
        t.font = textView.font!
        t.color = textView.Color
        ZDictPickerField.Pick(dict as [String : AnyObject], selectedKey:from[0], textInfo:t, got:got)
    }
    
    func HandleFocus(_ focused:Bool, from:ZView) {
        h1.Show(focused)
    }
    
    func updateStrings() {
        strings[currentLang] = textView.text ?? ""
    }
    
    fileprivate func updateButtons() {
        if let i = langs.index(of: currentLang) {
            leftButton.Usable = (i > 0)
            rightButton.Usable = (i < langs.count - 1)
        }
        deleteButton.Usable = (currentLang != "en")
        addButton.Usable = (langs.count < possibleLangs.count)
        flagButton.SetImage(ZImage(named:currentLang + ".png"))
    }
}


