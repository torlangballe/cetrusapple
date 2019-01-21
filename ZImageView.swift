//
//  ZImageView.swift
//
//  Created by Tor Langballe on /20/10/15.
//

// #package com.github.torlangballe.cetrusandroid

import UIKit

class ZImageView: ZCustomView, ZImageLoader {
    var image: ZImage? = nil
    var maxSize = ZSize()
    var margin = ZSize()
    var hightlightTint = ZColor(white:0.4)
    var downloadUrl = ""
    var edited = false
    var minUrlImageSize = ZSize() // if not null, and downloaded image is < w and h of this, dont show
    var alignment = ZAlignment.None // to align when contentMode is fit/scale
    
    init(zimage:ZImage? = nil, name:String = "ZImageView", maxSize:ZSize = ZSize()) {
        super.init(name:name)
        objectName = name
        self.maxSize = maxSize
        image = zimage
        isAccessibilityElement = true
    }
    
    init(namedImage:String, scaleInsets:ZRect = ZRect.Null, maxSize:ZSize = ZSize()) {
        super.init(name:namedImage)
        objectName = namedImage
        self.maxSize = maxSize
        
        if let im = ZImage.Named(namedImage) {
            if !scaleInsets.IsNull {
                image = im.Make9PatchImage(capInsets:scaleInsets)
            } else {
                image = im
            }
        }
    }
    
    convenience init(url:String, maxSize:ZSize = ZSize(), downloaded:((_ success:Bool)->Void)? = nil) {
        self.init(zimage:nil, name:url, maxSize:maxSize)
        downloadUrl = url
        if !url.isEmpty {
            self.DownloadFromUrl(url) { (sucess) in }
        }
    }
    
    // #swift-only:
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // #end
    
//    override func sizeThatFits(_ size: CGSize) -> CGSize {
//        if !maxSize.IsNull(){
//            return maxSize.GetCGSize()
//        }
//        let s = ZSize(super.sizeThatFits(size))
//        return (s + margin * 2.0).GetCGSize()
//    }
//    
    override func CalculateSize(_ total: ZSize) -> ZSize {
        var s = minSize
        if image != nil {
            s = image!.Size
        }
        if (!maxSize.IsNull()) {
            s = ZRect(size:maxSize).Align(s, align:ZAlignment.Center | ZAlignment.Shrink).size
        }
        return s
    }

    /* raw-kotlin: override */ func SetImage(_ image:ZImage?, _ downloadUrl:String = "") {
        self.downloadUrl = downloadUrl
        self.image = image
//        if minSize != nil && image != nil {
//            if image!.Size < minSize! {
//            }
//        }
        Expose()
    }
    
    override func DrawInRect(_ rect: ZRect, canvas: ZCanvas) {
        super.DrawInRect(rect, canvas:canvas)
        if image != nil {
            var drawImage = image!
            if (isHighlighted) {
                drawImage = drawImage.TintedWithColor(ZColor(white:0.5))
            }
            let r = LocalRect.Align(drawImage.Size, align:ZAlignment.Center | ZAlignment.Shrink)
            canvas.DrawImage(drawImage, destRect:r)
            if isFocused {
                ZFocus.Draw(canvas, rect:r, corner:10.0)
            }
        }
    }
//    
//
//    override func AddTarget(_ t: ZCustomView?, forEventType:ZControlEventType) {
//        touchInfo.tapTarget = t
//        assert(forEventType == .pressed)
//        isUserInteractionEnabled = true
//        isAccessibilityElement = true
//        accessibilityTraits |= UIAccessibilityTraitButton
//    }
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






