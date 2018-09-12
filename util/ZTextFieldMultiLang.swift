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
   
        addButton.AddTarget(self, forEventType:.pressed)
        h1.Add(addButton, align:.Right | .Bottom)
        
        rightButton.AddTarget(self, forEventType:.pressed)
        h1.Add(rightButton, align:.Right | .Bottom)
        
        flagButton.AddTarget(self, forEventType:.pressed)
        h1.Add(flagButton, align:.Right | .Bottom)
        
        leftButton.AddTarget(self, forEventType:.pressed)
        h1.Add(leftButton, align:.Right | .Bottom)
        
        deleteButton.AddTarget(self, forEventType:.pressed)
        h1.Add(deleteButton, align:.Left | .Bottom)

        Add(h1, align:.Right | .Bottom | .HorExpand | .NonProp, marg:ZSize(4, 4))
        
        updateButtons()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func HandlePressed(_ sender: ZView, pos: ZPos) {
        switch sender.View() {
            case rightButton:
                if let i = langs.index(of: currentLang) {
                    updateStrings()
                    currentLang = langs[i+1]
                    textView.text = strings[currentLang]
                    updateButtons()
                }

            case leftButton:
                if let i = langs.index(of: currentLang) {
                    updateStrings()
                    currentLang = langs[i-1]
                    textView.text = strings[currentLang]
                    updateButtons()
                }

            case deleteButton:
                strings.removeValue(forKey: currentLang)
                langs.removeIf {$0 == self.currentLang }
                currentLang = langs[0]
                textView.text = strings[currentLang]
                updateButtons()
            
            case addButton:
                let newLangs = possibleLangs.subtract(langs)
                getNewLang(newLangs) { [weak self] (key, val) in
                    if key != nil {
                        self!.updateStrings()
                        self!.currentLang = key!
                        self!.langs.append(key!)
                        self!.updateButtons()
                        self!.textView.text = ""
                    }
                }
            
            default:
                break
        }
    }

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


