//
//  ZImageView.swift
//  Zed
//
//  Created by Tor Langballe on /20/10/15.
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

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ZImageView: UIImageView, ZView, ZImageLoader, ZTimerOwner {
    // use contentMode for aspect fill etc
    weak var tapTarget: ZCustomView? = nil
    var objectName: String
    var maxSize = ZSize()
    var minSize : ZSize? = nil
    var hightlightTint = ZColor(white:0.4)
    var touchDownRepeatSecs = 0.0
    var touchDownRepeats = 0
    let touchDownRepeatTimer = ZRepeater()
    var downloadUrl = ""
    var edited = false
    var minUrlImageSize = ZSize() // if not null, and downloaded image is < w and h of this, dont show
    var alignment = ZAlignment.None // to align when contentMode is fit/scale
    private var handlePressedInPosFunc: ((_ pos:ZPos)->Void)? = nil
    
    init(zimage:ZImage? = nil, name:String = "ZImageView", maxSize:ZSize = ZSize()) {
        objectName = name
        self.maxSize = maxSize
        super.init(image:zimage)
        self.contentMode = .scaleAspectFit
        isAccessibilityElement = true
    }
    
    init(namedImage:String, insets:ZRect = ZRect.Null, maxSize:ZSize = ZSize()) {
        objectName = namedImage
        self.maxSize = maxSize
        if var image = ZImage(named:namedImage) {
            if !insets.IsNull {
                image = image.MakeScaleImage(capInsets:insets)
            }
            super.init(image:image)
            self.contentMode = UIViewContentMode.scaleAspectFit
        } else {
            super.init(image:nil)
        }
    }
    
    convenience init(url:String, maxSize:ZSize = ZSize(), downloaded:((_ success:Bool)->Void)?=nil) {
        self.init(zimage:nil, name:url, maxSize:maxSize)
        downloadUrl = url
        if !url.isEmpty {
            self.DownloadFromUrl(url) { (sucess) in }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func View() -> UIView {
        return self
    }
    
    var HandlePressedInPosFunc: ((_ pos:ZPos)->Void)? {
        set {
            handlePressedInPosFunc = newValue
            isUserInteractionEnabled = true
            isAccessibilityElement = true
            accessibilityTraits |= UIAccessibilityTraitButton
            if highlightedImage == nil && image != nil {
                highlightedImage = image!.TintedWithColor(hightlightTint)
            }
        }
        get {
            return handlePressedInPosFunc;
        }
    }
    
    override func layoutSubviews() {
//        if _isDebugAssertConfiguration() {
//            if accessibilityLabel == nil && isAccessibilityElement { // isAccessibilityElement is BOOL, not Boolean
//                //!                print("ZImageView: No accessiblity label")
//            }
//        }
        if handlePressedInPosFunc != nil {
            isUserInteractionEnabled = true
            if highlightedImage == nil && image != nil {
                highlightedImage = image!.TintedWithColor(hightlightTint)
            }
        }
        if alignment != .None && image != nil && contentMode == .scaleAspectFit {
            var r = LocalRect.Align(ZSize(image!.size), align:alignment)
            r = r / LocalRect.size
            //   layer.contentsRect = r.GetCGRect()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            if tapTarget != nil {
                let pos = ZPos(touches.first!.location(in: self))
                tapTarget?.HandleTouched(self, state:.began, pos:pos, inside:true)
                if touchDownRepeatSecs != 0 {
                    touchDownRepeats = 0
                    self.touchDownRepeatTimer.Set(self.touchDownRepeatSecs, owner:self) { [weak self] () in
                        if self?.touchDownRepeats > 2 {
                            self?.tapTarget!.HandlePressed(self!, pos:pos)
                        }
                        self?.touchDownRepeats += 1
                        return true
                    }
                }
            }
            isHighlighted = true
            Expose()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            var handled = false
            isHighlighted = false
            self.PerformAfterDelay(0.05) { [weak self] () in
                self?.Expose()
            }
            if tapTarget != nil || handlePressedInPosFunc != nil {
                let pos = ZPos(touches.first!.location(in: self))
                let inside = LocalRect.Contains(pos)
                if tapTarget != nil {
                    handled = tapTarget!.HandleTouched(self, state:.ended, pos:pos, inside:inside)
                }
                if inside && !handled {
                    if handlePressedInPosFunc != nil {
                        handlePressedInPosFunc!(pos)                        
                    } else {
                        tapTarget?.HandlePressed(self, pos:ZPos(touches.first!.location(in: self)))
                    }
                }
                touchDownRepeatTimer.Stop()
            }
            if self.animationImages != nil {
                self.startAnimating()
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            if tapTarget != nil {
                tapTarget?.HandleTouched(self, state:.canceled, pos:ZPos(), inside:false)
            }
            isHighlighted = false
            Expose()
            touchDownRepeatTimer.Stop()
            if self.animationImages != nil {
                self.startAnimating()
            }
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if !maxSize.IsNull(){
            return maxSize.GetCGSize()
        }
        return super.sizeThatFits(size)
    }
    
    func SetImage(_ image:ZImage?, downloadUrl:String = "") {
        self.downloadUrl = downloadUrl
        self.image = image
        if minSize != nil && image != nil {
            if image!.Size < minSize! {
            }
        }
        Expose()
    }
    
    func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
        tapTarget = t
        assert(forEventType == .pressed)
        isUserInteractionEnabled = true
        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitButton
        if highlightedImage == nil && image != nil {
            highlightedImage = image!.TintedWithColor(hightlightTint)
        }
    }
    
    func SetAnimatedImages(_ images:[ZImage], durationForAll:Float32, start:Bool = true) {
        animationImages = images
        self.animationDuration = TimeInterval(durationForAll)
        if start {
        startAnimating()
            startAnimating()
        }
    }

    func Animate(_ on:Bool) {
        if on {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
    
    func SetAnimatedImagesFromWildcard(_ wildcard:String, durationForAll:Float32, start:Bool = true) {
        let images = ZImage.GetNamedImagesFromWildcard(wildcard)
        if images.count > 0 {
            SetAnimatedImages(images, durationForAll:durationForAll, start:start)
        } else {
            SetImage(nil)
        }
    }
}

protocol ZImageLoader: class {
    func SetImage(_ image:ZImage?, downloadUrl:String)
}

extension ZImageLoader {
    func DownloadFromUrl(_ url:String, cache:Bool = true, done:((_ success:Bool)->Void)?=nil) { // , contentMode mode: UIViewContentMode
        
        ZImage.DownloadFromUrl(url, cache:cache) { [weak self] (image) in
            if image != nil {
                self?.SetImage(image, downloadUrl:url)
                done?(true)
            } else {
                done?(false)
            }
        }
    }
}

