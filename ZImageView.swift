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

class ZImageView: UIImageView, ZView, ZControl, ZImageLoader {
    func Control() -> UIControl {
        return UIControl()
    }
    var High: Bool {
        get {
            return isHighlighted
        }
        set {
            isHighlighted = newValue
        }
    }

    // use contentMode for aspect fill etc
    var objectName: String
    var maxSize = ZSize()
    var minSize : ZSize? = nil
    var margin = ZSize()
    var touchInfo = ZTouchInfo()
    var hightlightTint = ZColor(white:0.4)
    var downloadUrl = ""
    var edited = false
    var minUrlImageSize = ZSize() // if not null, and downloaded image is < w and h of this, dont show
    var alignment = ZAlignment.None // to align when contentMode is fit/scale
    
    init(zimage:ZImage? = nil, name:String = "ZImageView", maxSize:ZSize = ZSize()) {
        objectName = name
        self.maxSize = maxSize
        super.init(image:zimage)
        self.contentMode = .scaleAspectFit
        isAccessibilityElement = true
    }
    
    init(namedImage:String, scaleInsets:ZRect = ZRect.Null, maxSize:ZSize = ZSize()) {
        objectName = namedImage
        self.maxSize = maxSize
        
        if var image = ZImage(named:namedImage) {
            if !scaleInsets.IsNull {
                image = image.Make9PatchImage(capInsets:scaleInsets)
            }
            super.init(image:image)
            self.contentMode = UIViewContentMode.scaleAspectFit
        } else {
            super.init(image:nil)
        }
    }
    
    convenience init(url:String, maxSize:ZSize = ZSize(), downloaded:((_ success:Bool)->Void)? = nil) {
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
            touchInfo.handlePressedInPosFunc = newValue
            isUserInteractionEnabled = true
            isAccessibilityElement = true
            accessibilityTraits |= UIAccessibilityTraitButton
            if highlightedImage == nil && image != nil {
                highlightedImage = image!.TintedWithColor(hightlightTint)
            }
        }
        get {
            return touchInfo.handlePressedInPosFunc;
        }
    }
    
    override func layoutSubviews() {
        //        if _isDebugAssertConfiguration() {
        //            if accessibilityLabel == nil && isAccessibilityElement { // isAccessibilityElement is BOOL, not Boolean
        //                //!                print("ZImageView: No accessiblity label")
        //            }
        //        }
        if touchInfo.handlePressedInPosFunc != nil {
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
            touchInfoBeginTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoEndTracking(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
        if animationImages != nil {
            startAnimating()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isUserInteractionEnabled {
            touchInfoTrackingCanceled(touchInfo:touchInfo, view:self, touch:touches.first!, event:event)
        }
        if animationImages != nil {
            startAnimating()
        }
    }
        
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if !maxSize.IsNull(){
            return maxSize.GetCGSize()
        }
        let s = ZSize(super.sizeThatFits(size))
        return (s + margin * 2.0).GetCGSize()
    }
    
    func SetImage(_ image:ZImage?, _ downloadUrl:String = "") {
        self.downloadUrl = downloadUrl
        self.image = image
        if minSize != nil && image != nil {
            if image!.Size < minSize! {
            }
        }
        Expose()
    }
    
    func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
        touchInfo.tapTarget = t
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
        animationDuration = TimeInterval(durationForAll)
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
    func SetImage(_ image:ZImage?, _ downloadUrl:String)
}

extension ZImageLoader {
    func DownloadFromUrl(_ url:String, cache:Bool = true, done:((_ success:Bool)->Void)? = nil) { // , contentMode mode: UIViewContentMode
        let s = self
        ZImage.DownloadFromUrl(url, cache:cache) { (image) in
            if image != nil {
                s.SetImage(image, url)
                done?(true)
            } else {
                done?(false)
            }
        }
    }
}





