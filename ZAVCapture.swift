//
//  ZAVCapture.swift
//  capsulefm
//
//  Created by Tor Langballe on /24/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

typealias ZAVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer

class ZAVCapture : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    var stillImageHandler:((_ image:ZImage?, _ error:Error?)->Void)? = nil

    var captureSession = AVCaptureSession()
    let stillImageOutput = AVCapturePhotoOutput()
    var error: NSError?
    var getFrame: ((_ image:ZImage)->Void)? = nil
    var isBack = true
    var available = false
    var previewLayer:ZAVCaptureVideoPreviewLayer? = nil

    func StartPhoto() -> Error? { // https://stackoverflow.com/questions/39894630/how-to-get-front-camera-back-camera-and-audio-with-avcapturedevicediscoverysess
        if let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: isBack ? .back : .front) {
            captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480 // AVCaptureSessionPresetPhoto
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                try captureDevice.lockForConfiguration()
            } catch let error as NSError {
                return error
            }
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()

            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            captureSession.startRunning()
        }
        return nil
    }

    func StartVideo(back:Bool = true, get:@escaping (_ image:ZImage)->Void) -> Error? {
        //let v = ZGetTopViewController() as! ZViewController
        getFrame = get
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        isBack = back
        captureSession.sessionPreset = AVCaptureSession.Preset.low

        if let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: isBack ? .back : .front) {
            do {
                let input = try AVCaptureDeviceInput(device:captureDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    try captureDevice.lockForConfiguration()
                    captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 15)
                    captureDevice.unlockForConfiguration()
                }
            } catch let error as NSError {
                return error
            }
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32) ]
            output.alwaysDiscardsLateVideoFrames = true
            captureSession.commitConfiguration()
            let queue = DispatchQueue(label: "videoQueue", attributes: [])
            output.setSampleBufferDelegate(self, queue:queue)
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            captureSession.startRunning()
        }
        return nil
    }

    func Stop() {
        captureSession.stopRunning()
    }
    
    func SetPreviewFrame(_ frame:ZRect) {
        previewLayer?.frame = frame.GetCGRect()
    }

    func SetPreviewOrientation(_ orientation:ZScreen.Layout) {
        var o = AVCaptureVideoOrientation.portrait
        switch orientation {
        case .portrait:
            o = .portrait
        case .landscapeLeft:
            o = .landscapeRight
        case .landscapeRight:
            o = .landscapeLeft
        case .portraitUpsideDown:
            o = .portraitUpsideDown
        }
        previewLayer?.connection?.videoOrientation = o
        if let c = stillImageOutput.connection(with:AVMediaType.video) {
            c.videoOrientation = o
        }
    }

    func CreatePreviewLayer(_ rect:ZRect) -> ZAVCaptureVideoPreviewLayer? {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if previewLayer != nil {
            previewLayer!.bounds = rect.GetCGRect()
            previewLayer!.position = rect.Center.GetCGPoint()
            previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            SetPreviewOrientation(ZScreen.Orientation())
            //            if let videoConnection = stillImageOutput.connection(withMediaType:AVMediaTypeVideo) {
            //  videoConnection.videoOrientation =
            // }

            return previewLayer
        }
        return nil
    }
    
    func GetImage(_ done:@escaping (_ image:ZImage?, _ error:Error?)->Void) {
        stillImageHandler = done

        var videoConnection:AVCaptureConnection? = nil
        for connection in stillImageOutput.connections {
            let c = connection 
            for port in c.inputPorts {
                if port.mediaType == AVMediaType.video {
                    videoConnection = c
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }

        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        
        stillImageOutput.capturePhoto(with:settings, delegate:self)
/*
        stillImageOutput.captureStillImageAsynchronously(from:videoConnection) { (buffer, error) in
            if error != nil {
                done(nil, error)
                return
            }
            
            if let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:buffer!, previewPhotoSampleBuffer:nil) {
                var image = UIImage(data: dataImage)
                image = image!.GetRotationAdqjusted()
                done(image, nil)
            }
        }   
 */
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let image = ZImageFromSampleBuffer(sampleBuffer)
//        image = image!.GetRotationAdjusted(flip:!isBack)
        ZMainQue.async { [weak self] () in
            self?.getFrame?(image!)
        }
    }

    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if error != nil {
            stillImageHandler?(nil, error)
            return
        }
        
        if let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:photoSampleBuffer!, previewPhotoSampleBuffer:nil) {
            var image = UIImage(data: dataImage)
            image = image!.GetRotationAdjusted(flip:!isBack)
            ZMainQue.async { [weak self] () in
                self?.stillImageHandler?(image, nil)
            }
        }
    }

    private func cameraWithPosition(_ pos:AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        if let camera = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front).devices.first {
            return camera
        }
//
//        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
//        for d in devices ?? [] {
//            let dev = d { //as? AVCaptureDevice {
//                if dev.position == pos {
//                    return dev
//                }
//            }
//        }
        return nil
    }
    
    @discardableResult func FlipCameras() -> ZError? {
        captureSession.beginConfiguration()
        let currentCameraInput = captureSession.inputs[0] as! AVCaptureDeviceInput
        captureSession.removeInput(currentCameraInput)
    
        var newCamera:AVCaptureDevice? = nil
        
        let pos = (currentCameraInput.device.position == .back) ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        newCamera = cameraWithPosition(pos)

        do {
            let newVideoInput = try AVCaptureDeviceInput(device:newCamera!)
            captureSession.addInput(newVideoInput)
        } catch let error as NSError {
            return error as? ZError
        }
        captureSession.commitConfiguration()
        SetPreviewOrientation(ZScreen.Orientation())
        isBack = !isBack
        return nil
    }
    
    static func CheckCameraAuthorized(handler:@escaping (_ authorized:Bool)->Void) {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  .authorized {
            handler(true)
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
                ZMainQue.async {
                    handler(granted)
                }
            }
        }
    }
    
    @objc func cameraIsReady(notification :NSNotification ) {
        available = true
    }

    static func CheckIfCameraAvailable() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.cameraIsReady), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
    }
}

