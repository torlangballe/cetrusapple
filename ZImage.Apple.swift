//
//  zimage.swift
//  Zed
//
//  Created by Tor Langballe on /20/10/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

//import CoreImage
import CoreImage
import UIKit
import ImageIO
import AVFoundation

public typealias ZImage = UIImage

struct ZFaceInfo {
    var hasSmile = false
    var leftEyeClosed = false
    var rightEyeClosed = false
    var faceAngle:Float? = nil
}

extension ZImage {
    
    
    static func Named(_ name:String) -> ZImage? {
        if let i = ZImage(named:name) {
            if i.scale == 2 && ZIsTVBox(), let c = i.cgImage {
                return ZImage(cgImage: c, scale: 1, orientation: .up)
            }
            return i
        }
        return nil
    }
    
    static func Colored(color:ZColor, size:ZSize) -> ZImage {
        let rect = CGRect(x: 0, y: 0, width: size.w, height: size.h)
        UIGraphicsBeginImageContextWithOptions(size.GetCGSize(), false, 0)
        color.color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    var Size:ZSize {
        get { return ZSize(size) }
    }
    
    func Make9PatchImage(capInsets:ZRect) -> ZImage {
        var s = 1.0
        if scale == 1 && ZIsTVBox() {
            s = 2.0
        }
        let insets = UIEdgeInsets(top:CGFloat(capInsets.Min.y * s), left:CGFloat(capInsets.Min.x * s), bottom:CGFloat(capInsets.Max.y * s), right:CGFloat(capInsets.Max.x * s))
        return self.resizableImage(withCapInsets:insets, resizingMode:.tile)
    }
    
    func TintedWithColor(_ color:ZColor) -> ZImage {
        
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()
        
        // flip the image
        context?.scaleBy(x: 1, y: -1.0)
        context?.translateBy(x:0, y:-self.size.height)
        context?.setBlendMode(CGBlendMode.luminosity)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context?.clip(to: rect, mask: self.cgImage!)
        color.color.setFill()
        context?.fill(rect)
        
        // create uiimage
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if capInsets.bottom != 0 || capInsets.top != 0 || capInsets.right != 0 || capInsets.left != 0 {
            return newImage!.resizableImage(withCapInsets:capInsets, resizingMode:.tile)
        }

        return newImage!
    }
    // https://github.com/bryanjclark/ios-darken-image-with-cifilter/blob/master/UIImage%2BBlurAndDarken.m

    // http://nshipster.com/image-resizing/
    func GetScaledInSize(_ size:ZSize, proportional:Bool = true) -> ZImage? {
            var vsize = size
        if proportional {
            vsize = ZRect(size:size).Align(ZSize(self.size), align:.Center | .Shrink | .ScaleToFitProportionally).size
        }
        let width = Int(vsize.w) / Int(self.scale)
        let height = Int(vsize.h) / Int(self.scale)

        let colorSpaceInfo = CGColorSpaceCreateDeviceRGB()
        if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpaceInfo, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            context.interpolationQuality = CGInterpolationQuality.high
            context.draw(cgImage!, in: CGRect(origin:CGPoint.zero, size:CGSize(width:CGFloat(width), height:CGFloat(height))))
            if let cgimage = context.makeImage() {
                let image = ZImage(cgImage:cgimage)
                return image
            } else {
                print("no image")
            }
        } else {
            print("no context")
        }
        return nil
    }
    
    func GetCropped(_ crop:ZRect) -> ZImage {
        let imageRef = self.cgImage?.cropping(to: crop.GetCGRect())
        
        let bitmapInfo = imageRef?.bitmapInfo
        let colorSpaceInfo = imageRef?.colorSpace
        let bitmap = CGContext(data: nil, width: Int(crop.size.w), height: Int(crop.size.h), bitsPerComponent: (imageRef?.bitsPerComponent)!, bytesPerRow: (imageRef?.bytesPerRow)!, space: colorSpaceInfo!, bitmapInfo: (bitmapInfo?.rawValue)!)
        
        bitmap?.draw(imageRef!, in: CGRect(x: 0, y: 0, width: CGFloat(crop.size.w), height: CGFloat(crop.size.h)))
        let ref = bitmap?.makeImage()
        
        let resultImage = ZImage(cgImage:ref!)

        return resultImage;
    }

    fileprivate func hasAlpha() -> Bool {
        let alpha = self.cgImage?.alphaInfo
        let retVal = (alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast)
        return retVal
    }
    
    func GetLeftRightFlipped() -> ZImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: self.size.width, y: self.size.height)
        context.scaleBy(x: -self.scale, y: -self.scale)
        
        context.draw(self.cgImage!, in: CGRect(origin:CGPoint.zero, size: self.size))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
   
    func Normalized() -> ZImage {
      var imageOrientation: UIImage.Orientation = .up
        
        switch self.imageOrientation {
        case .down:
            imageOrientation = .downMirrored;
            
        case .downMirrored:
            imageOrientation = .down
            
        case .left:
            imageOrientation = .leftMirrored;
            
        case .leftMirrored:
            imageOrientation = .left;
            
        case .right:
            imageOrientation = .rightMirrored;
            
        case .rightMirrored:
            imageOrientation = .right;
            
        case .up:
            imageOrientation = .upMirrored;
            break;
            
        case .upMirrored:
            imageOrientation = .up;
        }
        
        let image = UIImage(cgImage:self.cgImage!, scale:self.scale, orientation:imageOrientation)
        return image
    }

    func GetRotationAdjusted(flip:Bool = false) -> ZImage { // adjustForScreenOrientation:Bool
        if (self.imageOrientation == .up) {
            //        return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, !self.hasAlpha(), self.scale)
        var rect = CGRect.zero
        rect.size = self.size

        self.draw(in: rect)
        var retVal = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        
        if retVal != nil && flip {
            retVal = retVal!.GetLeftRightFlipped()
        }
        return retVal!
    }

    func Rotated(deg:Double, around:ZPos? = nil) -> ZImage? {
        var pos = ZSize(size).GetPos() / 2
        if around != nil {
            pos = around!
        }
        let transform = ZMatrixForRotatingAroundPoint(pos, deg:deg)
        let cgi = cgImage!
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgi.bitsPerComponent, bytesPerRow: 0, space: cgi.colorSpace!, bitmapInfo: cgi.bitmapInfo.rawValue) else {
            return nil
        }
        
        context.concatenate(transform)        
        context.draw(cgi, in:CGRect(origin: .zero, size: size), byTiling:false)
        guard let CGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: CGImage)
    }
    
    func FixedOrientation() -> ZImage? {
        if self.imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Float.pi))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Float.pi))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat(Float.pi))
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage!.bitsPerComponent, bytesPerRow: 0, space: cgImage!.colorSpace!, bitmapInfo: cgImage!.bitmapInfo.rawValue) else {
            return nil
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage!, in:CGRect(x: 0, y: 0, width: size.height, height: size.width), byTiling:false)
        //(in: CGRect(x: 0, y: 0, width: size.height, height: size.width), image: cgImage!)
        default:
            context.draw(cgImage!, in:CGRect(origin: .zero, size: size), byTiling:false)
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let CGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: CGImage)
    }
}

extension ZImage {
    static var MainCache = ZImageCache()
    
    @discardableResult static func DownloadFromUrl(_ url:String, cache:Bool = true, maxSize:ZSize? = nil, done:((_ image:ZImage?)->Void)? = nil) -> ZURLSessionTask? {
        if cache {
            return MainCache.DownloadFromUrl(url, done:done)
        }
        //        let start = ZTime.Now()
        let req = ZUrlRequest.Make(.Get, url:url)
        return ZUrlSession.Send(req, onMain:false, makeStatusCodeError:true) { (resp, data, err) in
            if err != nil {
                ZDebug.Print("ZImage.DownloadFromUrl error:", err!.localizedDescription, url)
                ZMainQue.async {
                    done?(nil)
                }
                return
            }
            if data == nil {
                ZDebug.Print("ZImage.DownloadFromUrl data=null:", url)
                ZMainQue.async {
                    done?(nil)
                }
                return
            }
            var scale:CGFloat = 1.0
            let name = req.url!.deletingPathExtension().lastPathComponent
            if name.hasSuffix("@2x") {
                scale = 2
            } else if name.hasSuffix("@3x") {
                scale = 3
            }
            if var image = ZImage(data:data!, scale:scale) {
                if maxSize != nil && (image.Size.w > maxSize!.w || image.Size.h > maxSize!.h) {
                    if let small = image.GetScaledInSize(maxSize!) {
//                        ZDebug.Print("ZImage.Download: Scaling too big image:", image.Size, "max:", maxSize!, url)
                        image = small
                    } else {
                        ZDebug.Print("ZImage.Download: Failing too big image not scaleable:", image.Size, "max:", maxSize!, url)
                        ZMainQue.async {
                            done?(nil)
                        }
                        return
                    }
                }
                ZMainQue.async {
                    done?(image)
                }
            } else {
                ZMainQue.async {
                    done?(nil)
                }
            }
        }
    }
    
    func SaveToPng(_ file:ZFileUrl) -> ZError? {
      let data:ZData? = self.pngData() as ZData?
        if data != nil {
            if data!.SaveToFile(file) == nil {
                return nil
            }
        }
        return ZNewError("error storing image as png")
    }
    
    func SaveToJpeg(_ file:ZFileUrl, quality:Float = 0.8) -> ZError? {
        let data:ZData? = self.jpegData(compressionQuality:CGFloat(quality)) as ZData?
        if data != nil {
            if data!.SaveToFile(file) != nil {
                return nil
            }
        }
        return ZNewError("error storing image as png")
    }

    class func FromFile(_ file:ZFileUrl) -> ZImage? {
        if file.url != nil {
            do {
                let data = try ZData(contentsOf:file.url! as URL)
                return ZImage(data:data as Data)
            } catch {
                return nil
            }
        }
        return nil
    }    
}

func ZImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue:CGImageAlphaInfo.noneSkipLast.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        if let quartzImage = context?.makeImage() {
            CVPixelBufferUnlockBaseAddress(imageBuffer,CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            let image = UIImage(cgImage: quartzImage)
            return image
        }
    }
    return nil
}

func ZMakeImageFromDrawFunction(_ size:ZSize, scale:Float = 0, draw:(_ size:ZSize, _ canvas:ZCanvas)->Void) -> ZImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = CGFloat(scale)
    let renderer = UIGraphicsImageRenderer(size:size.GetCGSize(), format:format)
    let image = renderer.image { ctx in
        let canvas = ZCanvas(context:ctx.cgContext)
        draw(size, canvas)
    }
    return image
}

extension ZImage {
    func ForPixels(_ got:(_ pos:ZPos, _ color:ZColor)->Void) {
        let cgImage = self.cgImage
        let pixelData = cgImage?.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let rowBytes = cgImage?.bytesPerRow
        for y in 0 ..< Int(self.size.height) {
            for x in 0 ..< Int(self.size.width) {
                let pixelInfo = y * rowBytes! + x * 4
                let r = Double(data[pixelInfo]) / 255.0
                let g = Double(data[pixelInfo+1]) / 255.0
                let b = Double(data[pixelInfo+2]) / 255.0
                let a = Double(data[pixelInfo+3]) / 255.0
                got(ZPos(x, y), ZColor(r:r, g:g, b:b, a:a))
            }
        }
    }
    
    func GetCIImage() -> CIImage? {
        if let ci = self.ciImage {
            return ci
        }
        if let ci = CIImage(image:self) {
            return ci
        }
        return nil
    }
    
    func ClipToCircle(fit:ZSize = ZSize(0, 0)) -> ZImage? {
        var si = ZSize(size)
        var s = fit

        if fit.IsNull() {
            let w = (si.w > si.h) ? si.h : si.w
            s = ZSize(w, w)
        } else {
            let scale = max(fit.w / Double(size.width), fit.h / Double(size.height))
            si *= scale
        }
        var ir = ZRect(size:si)
        var r = ir.Align(s, align:.Center | .Shrink)
        return ZMakeImageFromDrawFunction(s) { (size, canvas) in
            let path = ZPath()
            ir.pos -= r.pos
            r.pos = ZPos(0, 0)
            path.AddOval(inrect:r)
            canvas.ClipPath(path)
            canvas.DrawImage(self, destRect:ir)
        }
    }

    static func GetNamedImagesFromWildcard(_ wild:String) -> [ZImage] {
        var images = [ZImage]()
        let folder = ZGetResourceFileUrl("")
        folder.Walk(wildcard:wild) { (furl, finfo) in
            if let image = ZImage.Named(furl.GetName()) {
                images.append(image)
            }
            return true
        }
        return images
    }
}

class ZImageUploader {
    var url:String = ""
    var strId:String = ""
    var error:ZError? = nil
    var image:ZImage? = nil
    var done:((_ uploader:ZImageUploader)->Void)? = nil
    
    func SetDone(_ done:@escaping (_ uploader:ZImageUploader)->Void) {
        self.done = done
        if !self.url.isEmpty {
            done(self)
        }
    }

    func SetUrl(_ url:String) {
        self.url = url
        done?(self) // done can be nil and ignored here...
    }
}

class ZImageCache {
    var maxHours = 24.0
    var maxSize:ZSize? = nil
    var maxByteSize:Int64? = nil

    struct Cache {
        var image: ZImage? = nil
        var stamp = ZTime()
        var getting = true
    }
    var cache = [String:Cache]()

    @discardableResult func DownloadFromUrl(_ url:String, done:((_ image:ZImage?)->Void)? = nil) -> ZURLSessionTask? {
        if url.isEmpty {
            done?(nil)
            return nil
        }
        if var c = cache[url] {
            if c.getting {
                if c.stamp.Since() > 60  {
                    cache.removeValue(forKey:url)
                    done?(nil)
                    return nil
                }
                ZPerformAfterDelay(2) { [weak self] () in
                    self?.DownloadFromUrl(url, done:done)
                }
                return nil
            }
            c.stamp = ZTime.Now()
            cache[url] = c
            done?(c.image)
            return nil
        }
        var totalSize:Int64 = 0
        for (u, c) in cache {
            if c.stamp.Since() > maxHours * 3600 || !c.getting && c.image == nil && ZMath.RandomN(10) == 5 {
                cache.removeValue(forKey:u)
            } else {
                totalSize += imageSize(c.image)
            }
        }
        while maxByteSize != nil && maxByteSize! < totalSize && cache.count > 0 {
            let oldestTupple = cache.reduce(cache.first!) { (r, t) in
                return t.1.stamp < r.1.stamp ? t : r
            }
            totalSize -= imageSize(oldestTupple.1.image)
            cache.removeValue(forKey:oldestTupple.0)
        }
        var c2 = Cache()
        c2.stamp = ZTime.Now()
        c2.getting = true
        self.cache[url] = c2
        return ZImage.DownloadFromUrl(url, cache:false, maxSize:maxSize) { (image) in
            if var c3 = self.cache[url] {
                c3.image = image
                c3.getting = false
                self.cache[url] = c3
                if image == nil {
                    print("null image:", url)
                }
            }
            done?(image)
        }
    }
    
    private func imageSize(_ image:ZImage?) -> Int64 {
        if image != nil {
            return Int64(ZSize(image!.size).Area() * 3) / 5
        }
        return 0
    }

}
