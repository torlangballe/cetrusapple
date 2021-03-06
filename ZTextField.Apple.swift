//
//  ZTextField.swift
//  Zed
//
//  Created by Tor Langballe on /13/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

//    static NSText *getFieldEditor(NSTextField *f)
//    return [ [ f window ] fieldEditor: YES forObject: f ];

typealias ZKeyboardType = UIKeyboardType
typealias ZAutocapitalizationType = UITextAutocapitalizationType
typealias ZReturnKeyType = UIReturnKeyType
typealias ZTextPosition = UITextPosition
typealias ZTextClearButtonMode = UITextField.ViewMode

protocol ZTextBase {
    var assumedLangCode: String { get }
    var Color: ZColor { get set }
    var TextString: String { get set }
    var Selection: (Int,Int) { get set }
    var KeyboardLocale : String { get }
}

func ZTextDismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

extension ZTextBase {
    var SelectedText: String {
        get {
            let (s, e) = Selection
            if s == e {
                return TextString
            }
            return ZStr.Body(TextString, pos:s, size:e - s)
        }
    }
    var KeyboardLangCode : String {
        get {
            return ZLocale.GetLangCodeAndCountryFromLocaleId(KeyboardLocale).0
        }
    }
}

struct ZKeyboardInfo : ZCopy {
    var keyboardType: ZKeyboardType? = nil
    var autoCapType: ZAutocapitalizationType? = nil
    var returnType: ZReturnKeyType? = nil
}

protocol ZTextEditDelegate : class {
    func HandleFocus(_ focused:Bool, from:ZView)
    func HandleTextShouldBeginEditing(_ from:ZView) -> Bool
    func HandleTextShouldEndEditing(_ from:ZView) -> Bool
    func HandleTextShouldReturn(_ from:ZView) -> Bool
    func HandleTextDidChange(_ from:ZView)
    func HandleTextDidChangeSelection()
}

extension ZTextEditDelegate {
    func HandleFocus(_ focused:Bool, from:ZView) {}
    @discardableResult func HandleTextShouldBeginEditing(_ from:ZView) -> Bool { return true }
    @discardableResult func HandleTextShouldEndEditing(_ from:ZView) -> Bool { return true }
    @discardableResult func HandleTextShouldReturn(_ from:ZView) -> Bool { return true }
    func HandleTextDidChange(_ from:ZView) { }
    func HandleTextDidChangeSelection() { }
}

class ZTextField : UITextField, UITextFieldDelegate, ZTextBase, ZView {
    var assumedLangCode = ""
    var minWidth: Double = 0
    var maxWidth: Double = 0
    var objectName = "ZTextField"
    var marginY = 4
    var margin = ZSize()
    var useMenu = true
    var edited = false
    private weak var target: ZTextEditDelegate? = nil

    var Color: ZColor {
        get { return ZColor(color:textColor!) }
        set { textColor = newValue.color }
    }

    var TextString: String {
        get { return text ?? "" }
        set { text = newValue   }
    }

    var KeyboardLocale : String {
        return self.textInputMode!.primaryLanguage!
    }

    var Real: Float64? {
        get { return text != nil ? Float64(text!) : nil }
        set {
            if newValue != nil {
                text = ZStr.Format("%lg", newValue!)
            } else {
                text = nil
            }
        }
    }
    
//    func SetPlaceholder(_ text:String, color:ZColor) {
//        attributedPlaceholder = ZAttributedString(string:text, attributes:[NSAttributedStringKey.foregroundColor:color.rawColor])
//    }
    
    init(text:String="", minWidth:Double = 0, maxWidth:Double=0, font:ZFont? = nil, alignment:ZAlignment = ZAlignment.Left, margin:ZSize = ZSize(0.0, 0.0)) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        super.init(frame:CGRect(x:0, y:0, width:10, height:10))
        if font != nil {
            self.font = font
        }
        self.text = text
        self.margin = margin
        self.SetAlignment(alignment)
        self.delegate = self
    }

    func View() -> UIView {
        return self
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var box = ZSize()
        if maxWidth != 0 {
            box.w = maxWidth
        }
        box.h = 1000;
        var gs = super.sizeThatFits(box.GetCGSize())
        if minWidth != 0.0 {
            gs.width = max(gs.width, CGFloat(minWidth))
        }
        if maxWidth != 0.0 {
            gs.width = min(gs.width, CGFloat(maxWidth))
        }
        gs.height = max(gs.height, 14)
        gs.height += CGFloat(2 * marginY)
        
        return gs
    }

    func SetAlignment(_ a: ZAlignment) {
        self.textAlignment = ZTextDraw.GetTextAdjustment(a)
    }
    
    func Unfocus() {
        self.resignFirstResponder()
    }

    var Selection:(Int,Int) {
        get {
            let r = self.selectedTextRange
            
            let s = self.offset(from: self.beginningOfDocument, to:r!.start)
            let e = self.offset(from: self.beginningOfDocument, to:r!.end)
            
            return (s, e)
        }
        set {
            if let stp = self.position(from: self.beginningOfDocument, offset:newValue.0), let etp = self.position(from: self.beginningOfDocument, offset:newValue.1) {
                let tr = self.textRange(from: stp, to:etp)
                self.selectedTextRange = tr
            }
        }
    }
    
    func SetTintColor(_ c:ZColor) {
        tintColor = c.color
    }
    
    func SetClearButtonMode(_ mode:ZTextClearButtonMode) {
        clearButtonMode = mode
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
        if let r = self.selectedTextRange {
            self.replace(r, withText:str)
        }
    }
    
    func EndEditing() {
        self.endEditing(true)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func becomeFirstResponder() -> Bool {
        target?.HandleFocus(true, from:self)
        return super.becomeFirstResponder()
    }
 
    func play(_ sender: AnyObject) {
    }

    func stop(_ sender: AnyObject) {
    }

    func newDocument(_ sender: AnyObject) {
    }

func SetTarget(_ target: ZTextEditDelegate) {
        self.target = target
    NotificationCenter.default.addObserver(self, selector:#selector(ZTextField.textFieldDidChange(_:)), name:UITextField.textDidChangeNotification, object:nil)
    }
    
    @objc func textFieldDidChange(_ notification:Notification) {
        if let from = notification.object as? UITextField {
            if from == self {
                target?.HandleTextDidChange(self)
            }
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if target != nil {
            return target!.HandleTextShouldBeginEditing(self)
        }
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if target != nil {
            return target!.HandleTextShouldEndEditing(self)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if target != nil {
            return target!.HandleTextShouldReturn(self)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        edited = true
        ZScrollView.ScrollViewToMakeItVisible(self)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    override func canPerformAction(_ action:Selector, withSender sender:Any?) -> Bool {
        #if os(iOS)
        if !useMenu {
            ZMainQue.async { () in
                UIMenuController.shared.setMenuVisible(false, animated:false)
            }
        }
        #endif
        return super.canPerformAction(action, withSender:sender)
    }
    
    func getRange(_ s:Int, e:Int) -> UITextRange? {
        let beginning = self.beginningOfDocument
        let start = self.position(from: beginning, offset:s)
        let end = self.position(from: beginning, offset:e)
        return self.textRange(from: start!, to:end!)
    }

    func GetKeyboardLocale() -> String {
        return self.textInputMode!.primaryLanguage!
    }
    
    func ShowClearButton(_ show:Bool) {
        self.clearButtonMode = show ? .always : .never
    }

    func SetPlaceholderText(_ placeholder:String, color:ZColor = ZColor()) {
        var col = color
        if col.undefined {
            if self.Color.GrayScale > 0.5 {
                col = ZColor(white:1, a:0.3)
            } else {
                col = ZColor(white:0, a:0.3)
            }
        }
        self.placeholder = placeholder
        self.attributedPlaceholder = NSAttributedString(string:placeholder, attributes:[NSAttributedString.Key.foregroundColor:col.color])
    }
 
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: CGFloat(margin.w), dy: CGFloat(margin.h))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: CGFloat(margin.w), dy: CGFloat(margin.h))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var g: CGFloat = 0
        var a: CGFloat = 0
        if clearButtonMode != .never {
            backgroundColor?.getWhite(&g, alpha:&a)
            if g < 0.5 {
                for view in subviews {
                    if view is UIButton {
                        let button = view as! UIButton
                        if let image = ZImage.Named("ztextclear.png") {
                            button.setImage(image, for:.highlighted)
                            button.setImage(image, for:UIControl.State())
                        }
                    }
                }
            }
        }
    }

    var tintedClearImage: UIImage?
}
