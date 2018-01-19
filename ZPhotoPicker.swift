//
//  ZPhotoPicker.swift
//  capsulefm
//
//  Created by Tor Langballe on /14/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit
import MobileCoreServices

// http://gracefullycoded.com/display-a-popover-in-swift/

var ipick = ZPhotoPicker()

class ZPhotoPicker : NSObject, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate {

    // Look in ZViewController for methods for getting image/cancel, has to be in a view controller ugh.
    
    var controller = UIImagePickerController()
    
    static func TakePhotoAtTarget(_ target:ZView, direction:ZAlignment = .Top, rect:ZRect = ZRect(), back:Bool = false, library:Bool = false, overlayImage:ZImage? = nil, done:@escaping (_ image:ZImage?)->Void) {
        if library {
            ipick.controller.sourceType = UIImagePickerControllerSourceType.photoLibrary
        } else {
            ipick.controller.sourceType = UIImagePickerControllerSourceType.camera
            if back {
                ipick.controller.cameraDevice = UIImagePickerControllerCameraDevice.rear
            } else {
                ipick.controller.cameraDevice = UIImagePickerControllerCameraDevice.front
            }
            ipick.controller.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.photo
        }
    //            ipick.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;

        ipick.controller.mediaTypes = [kUTTypeImage as String]
    //    ipick.allowsEditing = YES;

        if overlayImage != nil {
            let v = ZImageView(zimage:overlayImage!)
            v.frame = ZRect(0, 0, ZScreen.Main.size.w, ZScreen.Main.size.h - 100).GetCGRect()
            
            //            let overlayView = UIView(frame:ipick.controller.view.frame)
            //            overlayView.backgroundColor = UIColor(patternImage:overlayImage!)
            //overlayView.layer.opaque = false
            //overlayView.opaque = false
            //            ipick.controller.cameraOverlayView = overlayView
            ipick.controller.cameraOverlayView = v
        }
 
        if let top = ZGetTopZViewController() {
            top.imagePickerDone = done
            ipick.controller.delegate = top
            top.present(ipick.controller, animated:true, completion:nil)
        }
    }
}

