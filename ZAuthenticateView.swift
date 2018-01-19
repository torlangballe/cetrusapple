//
//  ZAuthenticateView.swift
//  Zed
//
//  Created by Tor Langballe on /7/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


private func createTextEditor(_ text:String) -> ZTextField {
    let w = ZTextField(text:text, minWidth:300, font:ZFont.Nice(22), alignment:.HorCenter)
    w.returnKeyType = .next
    w.SetAutoCorrect(false)
    w.Color = ZColor.White()
    w.SetBackgroundColor(ZColor(white:0, a:0.7))
    w.isOpaque = false
    w.marginY = 10
    w.ShowClearButton(true)
    return w
}

private func makeButton(_ imageName:String, _ voText:String) -> ZShapeView {
    let shape = ZShapeView(type:.circle, minSize:ZSize(54, 54))
    shape.strokeWidth = 2
    shape.strokeColor = ZColor.White()
    shape.image = ZImage(named:imageName)
    shape.accessibilityLabel = voText
    shape.imageMargin = ZSize(10, 10)
    return shape
}

class ZAuthenticateView: ZStackView, ZTextEditDelegate {
    var minPasswordLength = 8
    var emailEditor: ZTextField
    var passwordEditor: ZTextField
    var leftButton: ZShapeView? = nil
    var rightButton: ZShapeView
    let countLabel: ZLabel
    let isRegister: Bool
    var forgotButton: ZLabel? = nil
    var activityView = ZActivityIndicator(big:true)
    var h1 = ZHStackView(space:10)

    static weak var current:ZAuthenticateView? = nil
    
    init(email:String, image:ZImage? = nil, isRegister: Bool, cancel:Bool) {
        self.isRegister = isRegister
        emailEditor = createTextEditor(email)
        emailEditor.keyboardType = .emailAddress
        emailEditor.SetAutoCapType(.none)
        let pcol = ZColor(white:1, a:0.4)
        emailEditor.SetPlaceholderText(ZTS("email"), color:pcol) // placeholder text in password text field
        passwordEditor = createTextEditor("")
        passwordEditor.SetPlaceholderText(ZTS("password"), color:pcol) // placeholder text in password text field
        passwordEditor.isSecureTextEntry = true
        
        countLabel = ZLabel(text:"", minWidth:50, font:ZFont.Nice(20, style:.bold), align:.Right)
        countLabel.Color = ZColor.White()

        rightButton = makeButton("check", ZTS("OK"))    // VO name of OK button in login/register
        if cancel {
            leftButton = makeButton("cross", ZTS("Cancel")) // VO name of Cancel button in login/register
        }

        super.init(name:"ZAuthenticateView")

        ZAuthenticateView.current = self

        vertical = true
        space = 10
        margin = ZRect(8, 4, -8, -125)
        
        var title = ZTS("log in as registered user")      // VO for title above email/password in login
        var back = ZTS("I want to create a new account")  // VO for back button at top of login in register variant
        if isRegister {
            title = ZTS("create a new account") // VO for title above email/password in login
            back = ZTS("I already have an account")  // VO for back button at top of login in login variant
        }
        back = "◀︎  " + back
        let label = ZLabel(text:title, font:ZFont.Nice(24), align:.Center)
        label.Color = ZColor.White()
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        Add(label, align:.Center)

        let smallFontSize = 18.0
        if !cancel {
            let label = ZLabel(text:back, font:ZFont.Nice(smallFontSize), align:.Center)
            label.Color = ZColor.White()
            Add(label, align:.Left | .Top, marg:ZSize(0, 30))
            label.HandlePressedInPosFunc = { [weak self] (pos) in
                self?.reopen(isRegister:!isRegister)
            }
        }

        if image != nil {
            let logo = ZImageView(zimage:image, maxSize:ZSize(200, 32))
            Add(logo, align:.HorCenter | .Top, marg:ZSize(0, 40))
        }

        self.Add(emailEditor, align:.Center | .HorExpand | .NonProp, marg:ZSize(-8, 0))
        emailEditor.SetTarget(self)
        self.Add(passwordEditor, align:.Center | .HorExpand | .NonProp, marg:ZSize(-8, 0))
        passwordEditor.SetTarget(self)
        h1.Add(countLabel, align:.Left)
        
        if isRegister {
            forgotButton = ZLabel(text:ZTS("forgot password?"), font:ZFont.Nice(smallFontSize), align:.Center)
            forgotButton!.Color = ZColor.White()
            h1.Add(forgotButton!, align:.Left | .VertCenter)
            forgotButton!.HandlePressedInPosFunc = { [weak self] (pos) in
                self?.handleForgot()
            }
        }
        Add(h1, align:.Center | .HorExpand | .NonProp)

        h1.Add(rightButton, align:.Right | .Top)
        rightButton.AddTarget(self, forEventType:.pressed)
        if leftButton != nil {
            h1.Add(leftButton!, align:.Left | .Top)
            leftButton!.AddTarget(self, forEventType:.pressed)
        }
        h1.Add(activityView, align:.Right | .VertCenter)
        
        emailEditor.Focus()
        
        updateButtons()
    }

    deinit {
        if ZAuthenticateView.current == self {
            ZAuthenticateView.current = nil
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func HandlePressed(_ sender: ZView, pos:ZPos) {
        if leftButton != nil && sender.View() == leftButton! {
            self.Pop()
        } else if sender.View() == rightButton {
            authenticate(isRegister:isRegister, userId:emailEditor.text!, password:passwordEditor.text!)
        }
    }
    
    fileprivate func updateButtons() {
//        let enable = (passwordEditor.text?.count >= minPasswordLength)
//        rightButton.Usable = enable
//        if !useCancel {
//            leftButton.Usable = enable
//        }
    }
    
    func HandleTextDidChange(_ from:ZView) {
        let v = from.View()
        if v == passwordEditor {
            updateButtons()
            let len = passwordEditor.text?.count ?? 0
            if minPasswordLength > 2 {
                countLabel.text = "\(len)/\(minPasswordLength)"
                countLabel.Color = (len < minPasswordLength) ? ZColor(r:1, g:0.4, b:0.4) : ZColor.Green()
            }
        }
    }
    
    func HandleTextShouldReturn(_ from:ZView) -> Bool {
        switch(from.View()) {
        case emailEditor:
            passwordEditor.Focus()
            
        default:
            emailEditor.Focus()
        }
        return false
    }
    
    static func DisableForSend(_ disable:Bool = true) {
        //        activityView->Start(sending)
        current?.rightButton.Usable = !disable
        current?.leftButton?.Usable = !disable
        current?.emailEditor.Usable = !disable
        current?.passwordEditor.Usable = !disable
        if !disable {
            current?.updateButtons()
        }
    }
    
    internal func authenticate(isRegister:Bool, userId:String, password:String) {
    }

    internal func reopen(isRegister:Bool) {
    }

    internal func handleForgot() {
    }
}



