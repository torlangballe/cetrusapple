//
//  ZTextView.swift
//  capsulefm
//
//  Created by Tor Langballe on /15/1/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZTextView : UITextView, UITextViewDelegate, ZTextBase, ZView {
    var assumedLangCode = ""
    var minWidth: Double = 0
    var maxWidth: Double = 0
    var objectName = "ZTextView"
    private weak var target: ZTextEditDelegate? = nil
    var useMenu = true
    var maxLines = 0
    var edited = false
    var clearButton = ZImageView(namedImage:"ztext.clear@3x.png")
    var placeHolderText = ""

    var Color: ZColor {
        get { return ZColor(color:textColor!) }
        set { textColor = newValue.color }
    }

    var TextString: String {
        get { return text ?? "" }
        set { text = newValue   }
    }
    
    var TintColor: ZColor {
        get { return ZColor(color:UITextView.appearance().tintColor) }
        set { UITextView.appearance().tintColor = newValue.color }
    }

    var Selection: (Int,Int) {
        get {
            let range = self.selectedRange
            return (range.location, range.location + range.length)
        }
        set {
            var nv = newValue
            if nv.0 == -1 {
                nv.0 = max(0, text.count - 1)
            }
            if nv.1 == -1 {
                nv.1 = max(0, text.count - 1)
            }
            self.selectedRange = ZRange(location:nv.0, length:nv.1 - nv.0)
        }
    }

    var KeyboardLocale : String {
        return self.textInputMode!.primaryLanguage!
    }

    init(text:String="", minWidth:Double=0, maxWidth:Double=0, font:ZFont?=nil, alignment:ZAlignment = .Left, lines:Int=0, clearColor:ZColor? = nil) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        
        super.init(frame:CGRect(x:0, y:0, width:10, height:10), textContainer:nil)
        if font != nil {
            self.font = font
        }
        self.text = text
        maxLines = lines
        //        self.textContainer.maximumNumberOfLines = lines
        self.SetAlignment(alignment)
        self.delegate = self
        if clearColor != nil {
            self.addSubview(clearButton)
            clearButton.HandlePressedInPosFunc = { [weak self] pos in
                self?.text?.removeAll()
                self?.Expose() // removeAll above doesn't seem to trigger changed eventd
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        if clearButton.image != nil {
            let c = contentInset
            let m = ZSize(6 + Double(c.right), 6 + Double(c.bottom))
            clearButton.Rect = LocalRect.Align(ZSize(clearButton.image!.size), align:.Right | .Bottom, marg:m)
        }
        if !placeHolderText.isEmpty && self.text!.isEmpty {
            let canvas = ZCanvas()
            var text = ZTextDraw()
            text.color = ZColor(color:backgroundColor ?? UIColor.white).GetContrastingGray().OpacityChanged(0.3)
            text.text = placeHolderText
            text.alignment = .Top | .Left
            text.font = font ?? ZFont.Nice(20)
            text.rect = LocalRect.Expanded(ZSize(-6, -8))
            text.Draw(canvas)
        }
    }
    
    func SetMargins(_ margins:ZRect) {
        self.contentInset = UIEdgeInsetsMake(CGFloat(margins.Min.y), CGFloat(margins.Min.x), -CGFloat(margins.Max.y), -CGFloat(margins.Max.x))
    }
    
    func View() -> UIView {
        return self
    }
    
    func ScrollToMakeRangeVisible(_ range:ZRange) {
        self.scrollRangeToVisible(range)
        self.isScrollEnabled = false
        self.isScrollEnabled = true
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let inset = self.contentInset
        var tinfo = ZTextDraw()
        tinfo.text = self.text
        tinfo.font = self.font!
        var vsize = size
        vsize.height = 9999
        tinfo.rect = ZRect(size:ZSize(vsize))
        tinfo.rect += ZRect(Double(inset.left), Double(inset.top), -Double(inset.right), -Double(inset.bottom))
        tinfo.maxLines = max(1, maxLines) // self.textContainer.maximumNumberOfLines
        var s = tinfo.GetBounds().size
        
        s.w += Double(inset.left + inset.right)
        s.h += Double(inset.top + inset.bottom)
        
        s.h *= 1.1
        s.h += 12
        
        
        return s.GetCGSize()
    }
    
    
    override func canPerformAction(_ action:Selector, withSender sender:Any?) -> Bool {
        if !useMenu {
            ZMainQue.async { () in
                UIMenuController.shared.setMenuVisible(false, animated:false)
            }
        }
        return super.canPerformAction(action, withSender:sender)
    }

    func SetAlignment(_ a: ZAlignment) {
        self.textAlignment = ZTextDraw.GetTextAdjustment(a)
    }
    
    func Unfocus() {
        _ = self.resignFirstResponder()
    }
    
    func Focus() {
        _ = self.becomeFirstResponder()
    }
    
    func SetAutoCorrect(_ on:Bool) {
        self.autocorrectionType = on ? .yes : .no
    }
    
    func SetKeyboardType(_ type:ZKeyboardType) {
        self.keyboardType = type
    }
    
    func SetEnablesReturnKeyAutomatically(_ on:Bool) {
        self.enablesReturnKeyAutomatically = on
    }
    
    func SetKeyboardDark(_ dark:Bool) {
        self.keyboardAppearance = dark ? .dark : .light
    }
    
    func SetAutoCapType(_ type:ZAutocapitalizationType) {
        self.autocapitalizationType = type
    }
    
    func SetReturnKeyType(_ type:ZReturnKeyType) {
        self.returnKeyType = type
    }
    
    func InsertTextAtSelection(_ str: String) {
        let (start, _) = Selection
        if let r = self.selectedTextRange {
            self.replace(r, withText:str)
            let end = start + str.count
            Selection = (end, e:end)
        }
    }
    
    func EndEditing() {
        self.endEditing(true)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func becomeFirstResponder() -> Bool {
        target?.HandleFocus(true, from:self)
        let become = super.becomeFirstResponder()
        return become
    }
    
    override func resignFirstResponder() -> Bool {
        target?.HandleFocus(false, from:self)
        let resign = super.resignFirstResponder()
        return resign
    }
    
    func play(_ sender: AnyObject) {
    }
    
    func stop(_ sender: AnyObject) {
    }
    
    func newDocument(_ sender: AnyObject) {
    }
    
    func SetTarget(_ target: ZTextEditDelegate) {
        self.target = target
        NotificationCenter.default.addObserver(self, selector:#selector(ZTextView.textViewDidChange(_:)), name:NSNotification.Name.UITextViewTextDidChange, object:nil)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        target?.HandleTextDidChangeSelection()
    }

    func textViewDidChange(_ textView:UITextView) {
        target?.HandleTextDidChange(self)
        Expose() // for drawing placeholders
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if target != nil {
            return target!.HandleTextShouldBeginEditing(self)
        }
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if target != nil {
            return target!.HandleTextShouldEndEditing(self)
        }
        return true
    }
    
/*
    func textViewShouldReturn(textView: UITextView) -> Bool {
        return (target?.HandleTextShouldReturn(self))!
        //        if(((NStextViewWidget *)textView)->widget)
        //        ((NStextViewWidget *)textView)->widget->Event(ZTextBaseWgt::EV_RETURN_PRESSED, 0, true);
        //        [ textView resignFirstResponder ];
    }
  */
    func textViewDidBeginEditing(_ textView: UITextView) {
        ZScrollView.ScrollViewToMakeItVisible(self)
        super.becomeFirstResponder()
        edited = true
    }
    
    func textView(_ textView:UITextView, shouldChangeTextIn range:NSRange, replacementText text:String) -> Bool {
        if text == "\n" && target != nil {
            if target!.HandleTextShouldReturn(self) {
                return true
            }
        }
        return true
    }
    
    func getRange(_ s:Int, e:Int) -> UITextRange? {
        let beginning = self.beginningOfDocument
        let start = self.position(from: beginning, offset:s)
        let end = self.position(from: beginning, offset:e)
        return self.textRange(from: start!, to:end!)
    }
    
    @objc func handleCustomMenu() {
    }
    
    func AddMenuItemAndShow(_ items:[String:String]) {
        let menuController = UIMenuController.shared
        menuController.setTargetRect(self.frame, in:self.superview!)
        menuController.arrowDirection = UIMenuControllerArrowDirection.left;
        for (_, name) in items {
            let menuItem = UIMenuItem(title:name, action:#selector(ZTextView.handleCustomMenu))
            menuController.menuItems?.append(menuItem)
        }
        menuController.setMenuVisible(true, animated:true)
    }
    
    func ReplaceSelectedText(_ replaceText:String, positionAfter:Bool = false) {
        let (s, e) = Selection
        text = ZStr.Head(text, chars:s) + replaceText + ZStr.Body(text, pos:e)
        let end = s + replaceText.count
        if positionAfter {
            Selection = (end, e:end)
        } else {
            Selection = (s, e:end)
        }
    }
}

